/**
 * libcld
 * Copyright (c) 2015, Geoff Johnson, All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3.0 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.
 */

/**
 * An task object that uses a Comedi device.
 */
public class Cld.ComediTask : Cld.AbstractTask {

    /* Property backing fields. */
    protected Gee.Map<string, Cld.Object>? _channels = null;
    private Cld.Device _device = null;

    /**
     * The sub device reference name.
     */
    protected string devref = null;

    /**
     * The referenced device.
     */
    [Description(nick="Device", blurb="The referenced device")]
    public Cld.Device device {
        get {
            if (_device == null) {
                /* If the task references a parent device */
                if ((parent is Cld.ComediDevice) && (uri.contains (devref))) {
                    _device = parent as Cld.ComediDevice;
                }
            }

            return _device;
        }
        set { _device = value; }
    }

    /**
     * Comedi subdevice number.
     */
    [Description(nick="Subdevice", blurb="The number of subdevice of the device")]
    public int subdevice { get; set; }

    /**
     * Execution type.
     */
    [Description(nick="Execution Type", blurb="The method of aquisition or triggering")]
    public string exec_type { get; set; }

    /**
     * Input or output.
     */
    [Description(nick="Direction", blurb="input or output")]
    public string direction { get; set; }

    /**
     * Use this for polling tasks.
     */
    [Description(nick="Interval (ms)", blurb="The polling interval in milliseconds")]
    public int interval_ms { get; set; }

    /**
     * Sampling interval in nanoseconds for a single channel. This is the
     * inverse of the scan rate. Use this for asynchronous.
     */
    [Description(nick="Interval (ns)", blurb="The streaming acquisition scan interval in nanoseconds")]
    public int64 interval_ns { get; set; }

    /**
     * The resolution (in nanoseconds) of the time between samples of adjacent
     * channels (ie. the inverse of the sampling frequency) This parameter may
     * need to be adjusted to get streaming acquisition to work properly.
     */
    [Description(nick="Resolution (ns)", blurb="The resolution of streaming acquisition scan interval in nanoseconds")]
    public int resolution_ns { get; set; default = 100; }

    /**
     * A list of channel references.
     */
    protected Gee.List<string>? chrefs;

    /**
     * The channels that this task uses.
     */
    protected Gee.Map<string, Cld.Object>? channels;

    /**
     * A list of FIFOs for inter-process data transfer.
     * The data are paired a pipe name and file descriptor.
     */
    [Description(nick="fifos", blurb="A list of FIFO file descriptors")]
    public Gee.Map<string, int>? fifos;
    //public Gee.Map<string, int>? fifos { get; private set; }

    /**
     * The size of the internal data buffer
     */
    //public uint qsize { get; set; default = 65536; }
    public uint qsize = 65536;

    private Comedi.InstructionList instruction_list;
    protected const int NSAMPLES = 10;

    /**
     * Internal thread data for log file output handling.
     */
    private unowned GLib.Thread<void *> thread;
    private Mutex mutex = new Mutex ();
    private Thread task_thread;

    /**
     * Counts the total number of connected FIFOs.
     */
    private Cld.LogEntry entry;
    private int device_fd = -1;

    /**
     * A Comedi command field used only with streaming acquisition.
     */
    private Comedi.Command cmd;
    private uint[] chanlist;

    /* An array to map the chanlist[] index to a channel */
    private Cld.AIChannel[] channel_array;
    private uint scan_period_nanosec;

    /**
     * A queue for holding data to be processed. XXX Deque seems to be faster.
     */
    public Gee.Deque<float?> queue;

    private int64 start_time = get_monotonic_time ();
    private int64 count = 1;


    /**
     * Enables simultaneous starting of multiple asynchronous acquisitions.
     */
    private signal void do_cmd ();

    /**
     * Default construction.
     */
    construct {
        chrefs = new Gee.ArrayList<string> ();
        _channels = new Gee.TreeMap<string, Cld.Object> ();
        fifos = new Gee.TreeMap<string, int> ();
        set_active (false);
        queue = new Gee.LinkedList<float?> ();
    }

    public ComediTask () {
        id = "tk0";
        devref = "dev0";
        device = new ComediDevice ();
        exec_type = "polling";
        direction = "read";
        interval_ns = (int64)1e8;
    }

    /**
     * Construction using an XML node.
     */
    public ComediTask.from_xml_node (Xml.Node *node) {
        if (node->type == Xml.ElementType.ELEMENT_NODE &&
            node->type != Xml.ElementType.COMMENT_NODE) {
            id = node->get_prop ("id");

            /* Iterate through node children */
            for (Xml.Node *iter = node->children;
            iter != null; iter = iter->next) {
                if (iter->name == "property") {
                    switch (iter->get_prop ("name")) {
                        case "devref":
                            devref = iter->get_content ();
                            break;
                        case "subdevice":
                            subdevice = int.parse (iter->get_content ());
                            break;
                        case "exec-type":
                            exec_type = iter->get_content ();
                            break;
                        case "direction":
                            direction = iter->get_content ();
                            break;
                        case "interval-ms":
                            interval_ms = int.parse (iter->get_content ());
                            break;
                        case "interval-ns":
                            interval_ns = int64.parse (iter->get_content ());
                            break;
                        case "resolution-ns":
                            resolution_ns = int.parse (iter->get_content ());
                            break;
                        case "chref":
                            debug ("adding - %s", iter->get_content ());
                            chrefs.add (iter->get_content ());
                            break;
                        case "fifo":
                            fifos.set (iter->get_content (), -1);
                            break;
                        default:
                            break;
                    }
                }
            }
        }
    }

    public Gee.Map<string, Cld.Object>? get_channels () {
        lock (_channels) {
            _channels = get_children (typeof (Cld.Channel))
                                            as Gee.TreeMap<string, Cld.Object>;
        }

        return _channels;
    }

    public void set_channels (Gee.Map<string, Cld.Object> value) {
        /* remove all first */
        objects.unset_all (get_children (typeof (Cld.Channel)));
        objects.set_all (value);
    }

    public Gee.List<string> get_chrefs () {

        return chrefs;
    }

    public string get_devref () {

        return devref;
    }

    /**
     * {@inheritDoc}
     */
    public override void run () {
        entry = new Cld.LogEntry ();
        if (device == null) {
            error ("Task %s has no reference to a device.", id);
        }

        /* Select execution type */
        switch (exec_type) {
            case "streaming":
                foreach (var channel in _channels.values)
                    debug ("%s", channel.uri);
                do_async ();
                break;
            case "polling":
                switch (direction) {
                    case "read":
                        direction = "read";
                        break;
                    case "write":
                        direction = "write";
                        break;
                    default:
                        break;
                }

                do_polling ();
                break;
            default:
                break;
        }
    }

    /**
     * {@inheritDoc}
     */
    public override void stop () {
        if (active) {
            set_active (false);
            if (exec_type == "polling") {
                thread.join ();
            } else if (exec_type == "streaming" && (device is Cld.ComediDevice)) {
                (device as ComediDevice).dev.cancel (subdevice);
            }
        }

        foreach (int fd in fifos.values) {
            Posix.close (fd);
        }

    }

    /**
     * Adds a channel to the task's list of channels.
     */
    public void add_channel (Object channel) {
        _channels.set (channel.id, channel);
    }

    /**
     * Polling tasks spawn a thread of execution. Currently, a task is either input (read)
     * or output (write) though it could be possible to have a combination of the two
     * operating in a single task.
     */
    private void do_polling () {
        switch (direction) {
            case "read":
                // setup the device instruction list based on channel list and device
                set_insn_list ();
                break;
            case "write":
                foreach (var channel in objects.values) {
                    if (channel is Cld.AOChannel) {
                        (channel as Cld.AOChannel).raw_value = 0;
                    }
                }
                // no action required for now.
                break;
            default:
                break;
        }
        // Instantiate and launch the thread.
        if (!GLib.Thread.supported ()) {
            stderr.printf ("Cannot run polling without thread support.\n");
            set_active (false);
            return;
        }

        if (!active) {
            task_thread = new Thread (this);
            try {
                set_active (true);
                thread = GLib.Thread.create<void *> (task_thread.run, true);
            } catch (ThreadError e) {
                stderr.printf ("%s\n", e.message);
                set_active (false);
                return;
            }
        }
    }

    /**
     * A thread safe method to poll the queue.
     *
     * @return a data value from the queue.
     */
    public float poll_queue () {
        float val;
        lock (queue) {
            val = queue.poll_tail ();
        }

        return val;
    }

    /**
     * Asynchronous acquisition
     */
    private void do_async () {
        if (device == null) {
            error ("Task %s has no reference to a device.", id);
        }

        Comedi.loglevel (4);
        chanlist = new uint[_channels.size];
        channel_array = new Cld.AIChannel[_channels.size];

        debug ("device: %s\n", device.id);
        //(device as ComediDevice).dev.set_max_buffer_size (subdevice, 1048576);
        //(device as ComediDevice).dev.set_buffer_size (subdevice, 1048576);
        debug (" buffer size: %d", (device as ComediDevice).dev.get_buffer_size (subdevice));
        scan_period_nanosec = (uint)interval_ns;

        /* Make chanlist sequential and without gaps. XXX Need this for Advantech 1710. */
        foreach (var channel in _channels.values) {
            if ((channel as Channel).num >= _channels.size) {
                error ("Channel list must be sequential and with no gaps.");
                return;
            }
            chanlist[(channel as Channel).num] = Comedi.pack (
                                                             (channel as Channel).num,
                                                             (channel as Cld.AIChannel).range,
                                                             Comedi.AnalogReference.GROUND
                                                             );
            channel_array[(channel as AIChannel).num] = channel as Cld.AIChannel;
        }

        for (int i = 0; i < _channels.size; i++) {
            var channel = channel_array[i];
            //stdout.printf ("i: %d, num: %d\n", i, (channel as Channel).num);
        }

        int ret;
        /**
         * This comedilib function will get us a generic timed
         * command for a particular board.  If it returns -1,
         * that's bad.
         */
        ret = (device as ComediDevice).dev.get_cmd_generic_timed (subdevice,
                    out cmd, _channels.size, scan_period_nanosec);

        if (ret < 0) {
            debug ("comedi_get_cmd_generic_timed failed");
        }

        /* Modify parts of the command */
        prepare_cmd ();
        test_cmd ();

        do_select ();
    }

    private void prepare_cmd () {
        uint convert_nanosec = (uint)(resolution_ns * (GLib.Math.round ((double)scan_period_nanosec /
                               ((double)(_channels.size * resolution_ns)))));

        cmd.subdev = subdevice;
        cmd.flags = 0;//TriggerFlag.WAKE_EOS;
        cmd.start_src = Comedi.TriggerSource.NOW;
        cmd.start_arg = 0;
        cmd.scan_begin_src = Comedi.TriggerSource.FOLLOW;
        //cmd.scan_begin_arg = scan_period_nanosec; //nanoseconds;
    	cmd.convert_src = Comedi.TriggerSource.TIMER;
	    cmd.convert_arg = convert_nanosec;
        cmd.scan_end_src = Comedi.TriggerSource.COUNT;
        cmd.scan_end_arg = _channels.size;
        cmd.stop_src = Comedi.TriggerSource.NONE;//COUNT;
        cmd.stop_arg = 0;
        cmd.chanlist = chanlist;
        cmd.chanlist_len = _channels.size;
    }

    private void test_cmd () {
        int ret;

        ret = (device as Cld.ComediDevice).dev.command_test (cmd);

        debug ("test ret = %d\n", ret);
        if (ret < 0) {
		    Comedi.perror("comedi_command_test");
            return;
        }

    	dump_cmd ();

        ret = (device as Cld.ComediDevice).dev.command_test (cmd);

        debug ("test ret = %d\n", ret);
        if (ret < 0) {
		    Comedi.perror("comedi_command_test");
		    return;
        }

    	dump_cmd ();

        return;
	}

    /**
     * Used by streaming acquisition. Data is read from a device and pushed to a fifo buffer.
     */
    public async int do_select () {
        int total = 0;
        int ret = -1;
        int bufsz = 65536;
        uint raw;
        ulong bytes_per_sample;
        int subdev_flags = (device as Cld.ComediDevice).dev.get_subdevice_flags (subdevice);
        SourceFunc callback = do_select.callback;
        uint maxdata = (device as Cld.ComediDevice).dev.get_maxdata (0, 0);
        Comedi.Range [] crange = new Comedi.Range [_channels.size];

        int index = 0;
        foreach (var channel in _channels.values) {
            crange [index++] = (device as Cld.ComediDevice).dev.get_range (
                                        (channel as Cld.AIChannel).subdevnum,
                                        (channel as Cld.AIChannel).num,
                                        (channel as Cld.AIChannel).range);
        }

        if ((subdev_flags & Comedi.SubdeviceFlag.LSAMPL) != 0) {
            bytes_per_sample = sizeof (uint);
        } else {
            bytes_per_sample = sizeof (ushort);
        }

        device_fd = (device as Cld.ComediDevice).dev.fileno ();
        Posix.fcntl (device_fd, Posix.F_SETFL, Posix.O_NONBLOCK);

        set_active (true);

        /* Prepare to launch the thread when the do_cmd signal gets emitted */
        do_cmd.connect (() => {

            /* Launch select thread */
            GLib.Thread<int> thread = new GLib.Thread<int>.try ("bg_device_watch",  () => {
                /**
                 * This inline method will execute when the signal do_cmd is emitted and thereby
                 * enables a concurent start of multiple tasks.
                 *
                 */
                //debug ("Asynchronous acquisition started for ComediTask %s @ %lld", uri, GLib.get_monotonic_time ());
                ret = (device as ComediDevice).dev.command (cmd);

                debug ("test ret = %d\n", ret);
                if (ret < 0) {
                    Comedi.perror("comedi_command");
                }

                int count = 0;
                int front = 0;
                int back = 0;
                int nchan = _channels.size;

                var size = (device as ComediDevice).dev.get_buffer_size (subdevice);

                while (active) {
                    ushort[] buf = new ushort[bufsz];
                    index = 0;
                    Posix.fd_set rdset;

                    Posix.timespec timeout = Posix.timespec ();
                    Posix.FD_ZERO (out rdset);
                    Posix.FD_SET (device_fd, ref rdset);
                    timeout.tv_sec = 0;
                    timeout.tv_nsec = 50000000;
                    Posix.sigset_t sigset = new Posix.sigset_t ();
                    Posix.sigemptyset (out sigset);
                    ret = Posix.pselect (device_fd + 1, &rdset, null, null, timeout, sigset);

                    if (ret < 0) {
                        if (Posix.errno == Posix.EAGAIN) {
                            Comedi.perror("read");
                        }
                    //} else if (ret == 0) {
                        //warning ("%s hit timeout\n", uri);
                    } else if ((Posix.FD_ISSET (device_fd, rdset)) == 1) {
                        ret = (int)Posix.read (device_fd, buf, bufsz);
                        total += ret;
                        lock (queue) {
                            for (int i = 0; i < ret / bytes_per_sample; i++) {
                                /* convert buf[i] */
                                double meas = Comedi.to_phys (
                                                buf [i], crange [index++], maxdata);
                                //stdout.printf ("%6.3f ", meas);
                                if (index >= nchan) {
                                    index = 0;
                                    //stdout.printf ("\n");
                                }
                                /* queue as double */
                                queue.offer_head ((float) meas);
                                if (queue.size > qsize) {
                                    /* Dump the oldest value */
                                    queue.poll_tail ();
                                }
                            }
                           // if ((total % 640) == 0) { stdout.printf ("%d: total from %s %d  QSIZE: %d\n",Linux.gettid (), uri, total, queue.size); }
                        }
                    }
                }

                Idle.add ((owned) callback);
                return 0;
            });

            yield;
        });

        yield;

        return 0;
    }

    /**
     * This purpose of this is to allow an external signal to be relayed internally
     * which inturn starts a streaming acquisition thread. It should allow multiple
     * asynchronous acquisitions to start concurrently.
     */
    public void async_start () {
        do_cmd ();
    }


    private string cmd_src (uint src) {
        string buf = "";

        if ((src & Comedi.TriggerSource.NONE) != 0) buf = "none|";
        if ((src & Comedi.TriggerSource.NOW) != 0) buf = "now|";
        if ((src & Comedi.TriggerSource.FOLLOW) != 0) buf = "follow|";
        if ((src & Comedi.TriggerSource.TIME) != 0) buf = "time|";
        if ((src & Comedi.TriggerSource.TIMER) != 0) buf = "timer|";
        if ((src & Comedi.TriggerSource.COUNT) != 0) buf = "count|";
        if ((src & Comedi.TriggerSource.EXT) != 0) buf = "ext|";
        if ((src & Comedi.TriggerSource.INT) != 0) buf = "int|";
        if ((src & Comedi.TriggerSource.OTHER) != 0) buf = "other|";

        if (Posix.strlen (buf) == 0)
            buf = "unknown src";
        //else
            //buf[strlen (buf)-1]=0;

        return buf;
    }

    private void dump_cmd () {
        GLib.debug ("subdevice:       %u", cmd.subdev);
        GLib.debug ("start:      %-8s %u", cmd_src (cmd.start_src), cmd.start_arg);
        GLib.debug ("scan_begin: %-8s %u", cmd_src (cmd.scan_begin_src), cmd.scan_begin_arg);
        GLib.debug ("convert:    %-8s %u", cmd_src (cmd.convert_src), cmd.convert_arg);
        GLib.debug ("scan_end:   %-8s %u", cmd_src (cmd.scan_end_src), cmd.scan_end_arg);
        GLib.debug ("stop:       %-8s %u", cmd_src (cmd.stop_src), cmd.stop_arg);
    }

    private void print_datum (uint raw, int channel_index, bool is_physical) {
        double physical_value;
        var channel = channel_array[channel_index] as Cld.AIChannel;
        Comedi.Range crange = (device as Cld.ComediDevice).dev.get_range (
                                                                subdevice,
                                                                channel_index,
                                                                channel.range);

        uint maxdata = (device as Cld.ComediDevice).dev.get_maxdata (0, 0);
        if (!is_physical) {
            debug ("%u ",raw);
        } else {
            physical_value = Comedi.to_phys (raw, crange, maxdata);
            debug ("%#8.6g ", physical_value);
        }
    }

    /**
     * Build a Comedi instruction list for a single subdevice
     * from a list of channels.
     */
    private void set_insn_list () {
        Comedi.Instruction[] instructions = new Comedi.Instruction[get_channels ().size];
        int n = 0;

        instruction_list.n_insns = get_channels ().size;

        foreach (var channel in get_channels ().values) {
            instructions[n] = Comedi.Instruction ();
            instructions[n].insn = Comedi.InstructionAttribute.READ;
            instructions[n].data = new uint[NSAMPLES];
            instructions[n].subdev = (channel as Channel).subdevnum;

            if (channel is Cld.AIChannel) {
                instructions[n].chanspec = Comedi.pack (n,
                                                 (channel as AIChannel).range,
                                                 Comedi.AnalogReference.GROUND);
                instructions[n].n = NSAMPLES;
            } else if (channel is Cld.DIChannel) {
                instructions[n].chanspec = Comedi.pack (n, 0, 0);
                instructions[n].n = 1;
            }
            n++;
        }

        instruction_list.insns = instructions;
    }

    /**
     * Here again the task is input (read) or output (write)
     * exclusively but that could change as needed.
     */
    private void trigger_device () {
        switch (direction) {
            case "read":
                execute_instruction_list ();
                break;
            case "write":
                execute_polled_output ();
                break;
            default:
                break;
        }
    }

    /**
     * This method executes a Comedi Instruction list.
     */
    public void execute_instruction_list () {
        Comedi.Range range;
        uint maxdata;
        int ret, i = 0, j;
        double meas;

        /* Set the OOR behavior */
        Comedi.set_global_oor_behavior (Comedi.OorBehavior.NUMBER);

        ret = (device as Cld.ComediDevice).dev.do_insnlist (instruction_list);
        if (ret < 0)
            Comedi.perror ("do_insnlist failed:");

        foreach (var channel in get_channels ().values) {
            maxdata = (device as Cld.ComediDevice).dev.get_maxdata (
                        (channel as Cld.Channel).subdevnum, (channel as Cld.Channel).num);

            /* Analog Input */
            if (channel is Cld.AIChannel) {

                meas = 0.0;
                for (j = 0; j < NSAMPLES; j++) {
                    range = (device as Cld.ComediDevice).dev.get_range (
                        (channel as Cld.Channel).subdevnum, (channel as Cld.Channel).num,
                        (channel as Cld.AIChannel).range);

                    //debug ("range min: %.3f, range max: %.3f, units: %u", range.min, range.max, range.unit);
                    meas += Comedi.to_phys (instruction_list.insns[i].data[j], range, maxdata);
                    //debug ("instruction_list.insns[%d].data[%d]: %u, physical value: %.3f", i, j, instruction_list.insns[i].data[j], meas/(j+1));
                }

                meas = meas / (j);
                (channel as Cld.AIChannel).add_raw_value (meas);

                //debug ("Channel: %s, Raw value: %.3f", (channel as AIChannel).id, (channel as AIChannel).raw_value);
            } else if (channel is Cld.DIChannel) {
                meas = instruction_list.insns[i].data[0];
                if (meas > 0.0) {
                    (channel as Cld.DChannel).state = true;
                } else {
                    (channel as Cld.DChannel).state = false;
                }

                //debug ("Channel: %s, Raw value: %.3f", (channel as DIChannel).id, meas);
            }

            i++;
        }
    }

    public void execute_polled_output () {
        Comedi.Range range;
        uint maxdata,  data;
        double val;

        foreach (var channel in get_channels ().values) {

            if (channel is Cld.AOChannel) {
                range = (device as Cld.ComediDevice).dev.get_range (
                        (channel as Cld.Channel).subdevnum, (channel as Cld.AOChannel).num,
                        (channel as Cld.AOChannel).range);

                maxdata = (device as Cld.ComediDevice).dev.get_maxdata ((channel as Cld.Channel).subdevnum, (channel as Cld.AOChannel).num);
                val = (channel as Cld.AOChannel).scaled_value;
                data = (uint)((val / 100.0) * maxdata);
                /*
                 *debug ("%s scaled_value: %.3f raw_value: %.3f data: %u",
                 *        (channel as AOChannel).id,
                 *        (channel as AOChannel).scaled_value,
                 *        (channel as AOChannel).raw_value,
                 *        data);
                 */
                (device as Cld.ComediDevice).dev.data_write (
                    (channel as Cld.Channel).subdevnum, (channel as Cld.AOChannel).num,
                    (channel as Cld.AOChannel).range, Comedi.AnalogReference.GROUND, data);
            } else if (channel is Cld.DOChannel) {
                if ((channel as Cld.DOChannel).state)
                    data = 1;
                else
                    data = 0;
                //debug ("%s data value: %u", (channel as DOChannel).id, data);
                (device as Cld.ComediDevice).dev.data_write (
                    (channel as Cld.Channel).subdevnum,
                    (channel as Cld.DOChannel).num,
                    0, 0, data);
            }
        }
    }

    /**
     * A thread that is used to implement a polling task.
     */
    public class Thread {
        private ComediTask task;

        int interval_ms;

        public Thread (ComediTask task) {
            this.task = task;
        }

        /**
         *
         */
        public void * run () {
            Mutex mutex = new Mutex ();
            Cond cond = new Cond ();
            int64 end_time;
            task.start_time = get_monotonic_time ();
            task.count = 1;

            while (task.active) {
                lock (task) {
                    task.trigger_device ();
                }

                //GLib.debug ("--- %d ---", this.interval_ms);

                mutex.lock ();
                try {
                    end_time = task.start_time + task.count++ *
                                        task.interval_ms * TimeSpan.MILLISECOND;
                    while (cond.wait_until (mutex, end_time))
                        ; /* do nothing */
                } finally {
                    mutex.unlock ();
                }
            }

            return null;
        }
    }
}

/**
 * FIXME: ComediTask possibly shouldn't be the base class and additional
 *        interfaces/abstract classes should be created for polling and
 *        streaming task types. For now this is more of a place holder to
 *        split the functionality of the one class.
 */
public class Cld.ComediPollingTask : Cld.ComediTask {

    private Comedi.InstructionList instruction_list;

    public ComediPollingTask () {
        base ();
    }

    public ComediPollingTask.from_xml_node (Xml.Node *node) {
        base.from_xml_node (node);
    }

    /**
     * {@inheritDoc}
     */
    public override void run () {
        /* Start task */
        set_insn_list ();
        task.begin ();
    }

    /**
     * {@inheritDoc}
     */
    public override void stop () {
        /* Stop task */
        set_active (false);
    }

    private async void task () {
        set_active (true);
        while (active) {
            debug ("Task `%s' running", id);
            switch (direction) {
                case "read":
                    execute_read ();
                    break;
                case "write":
                    execute_write ();
                    break;
                default:
                    break;
            }
            yield nap (1000);
        }
    }

    /**
     * Build a Comedi instruction list for a single subdevice
     * from a list of channels.
     */
    private void set_insn_list () {
        Comedi.Instruction[] insns = new Comedi.Instruction[get_channels ().size];
        int n = 0;

        instruction_list.n_insns = get_channels ().size;

        foreach (var channel in get_channels ().values) {
            insns[n] = Comedi.Instruction ();
            insns[n].insn = Comedi.InstructionAttribute.READ;
            insns[n].data = new uint[NSAMPLES];
            insns[n].subdev = (channel as Channel).subdevnum;

            if (channel is Cld.AIChannel) {
                insns[n].chanspec = Comedi.pack (n,
                                                 (channel as Cld.AIChannel).range,
                                                 Comedi.AnalogReference.GROUND);
                insns[n].n = NSAMPLES;
            } else if (channel is Cld.DIChannel) {
                insns[n].chanspec = Comedi.pack (n, 0, 0);
                insns[n].n = 1;
            }
            n++;
        }

        instruction_list.insns = insns;
    }

    /**
     * This method executes a Comedi Instruction list.
     */
    public void execute_read () {
        Comedi.Range range;
        uint maxdata;
        int ret, i = 0, j;
        double meas;

        /* Set the OOR behavior */
        Comedi.set_global_oor_behavior (Comedi.OorBehavior.NUMBER);

        ret = (device as Cld.ComediDevice).dev.do_insnlist (instruction_list);
        if (ret < 0) Comedi.perror ("do_insnlist failed:");

        foreach (var channel in get_channels ().values) {
            maxdata = (device as Cld.ComediDevice).dev.get_maxdata (
                        (channel as Cld.Channel).subdevnum,
                        (channel as Cld.Channel).num);
            /* Analog Input */
            if (channel is Cld.AIChannel) {
                meas = 0.0;
                for (j = 0; j < NSAMPLES; j++) {
                    range = (device as Cld.ComediDevice).dev.get_range (
                        (channel as Cld.Channel).subdevnum,
                        (channel as Cld.Channel).num,
                        (channel as Cld.AIChannel).range);
                    meas += Comedi.to_phys (instruction_list.insns[i].data[j],
                                            range,
                                            maxdata);
                }
                meas = meas / (j);
                (channel as Cld.AIChannel).add_raw_value (meas);
            } else if (channel is Cld.DIChannel) {
                meas = instruction_list.insns[i].data[0];
                (channel as Cld.DChannel).state = (meas > 0.0) ? true : false;
            }
            i++;
        }
    }

    private void execute_write () {
        Comedi.Range range;
        uint maxdata, data;
        double val;


        foreach (var channel in get_channels ().values) {
            if (channel is Cld.AOChannel) {
                val = (channel as Cld.AOChannel).scaled_value;
                range = (device as Cld.ComediDevice).dev.get_range (
                        (channel as Cld.Channel).subdevnum,
                        (channel as Cld.AOChannel).num,
                        (channel as Cld.AOChannel).range);
                maxdata = (device as Cld.ComediDevice).dev.get_maxdata (
                    (channel as Cld.Channel).subdevnum,
                    (channel as Cld.AOChannel).num);
                data = (uint)((val / 100.0) * maxdata);
                (device as Cld.ComediDevice).dev.data_write (
                    (channel as Cld.Channel).subdevnum,
                    (channel as Cld.Channel).num,
                    (channel as Cld.AChannel).range,
                    Comedi.AnalogReference.GROUND, data);
            } else if (channel is Cld.DOChannel) {
                data = ((channel as Cld.DOChannel).state) ? 1 : 0;
                (device as Cld.ComediDevice).dev.data_write (
                    (channel as Cld.Channel).subdevnum,
                    (channel as Cld.DOChannel).num,
                    0, 0, data);
            }
        }
    }
}

/**
 * FIXME: ComediTask possibly shouldn't be the base class and additional
 *        interfaces/abstract classes should be created for polling and
 *        streaming task types. For now this is more of a place holder to
 *        split the functionality of the one class.
 */
public class Cld.ComediStreamingTask : Cld.ComediTask {

    public ComediStreamingTask () {
        base ();
    }

    public ComediStreamingTask.from_xml_node (Xml.Node *node) {
        base.from_xml_node (node);
    }

    /**
     * {@inheritDoc}
     */
    public override void run () {
        /* Start task */
        task.begin ();
    }

    /**
     * {@inheritDoc}
     */
    public override void stop () {
        /* Stop task */
        set_active (false);
    }

    private async void task () throws ThreadError {
        set_active (true);
        while (active) {
            debug ("Task `%s' running", id);
            yield nap (1000);
        }
    }
}

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
 * Mutiplexes data from multiple tasks.
 */
public class Cld.Multiplexer : Cld.AbstractContainer {

    /* Property backing fields */
    private Gee.List<string>? _taskrefs;
    private string _fname;
    private int _update_stride;

    /**
     * A list of channel references.
     */
    [Description(nick="Task References", blurb="A list of channel references")]
    public Gee.List<string>? taskrefs {
        get { return _taskrefs; }
        set { _taskrefs = value; }
    }

    /* The name that identifies an interprocess communication pipe or socket. */
    [Description(nick="Filename", blurb="The path to the inter-process communication pipe or socket")]
    public string fname {
        get { return _fname; }
        set { _fname = value; }
    }

    /* The update interval, in milliseconds, of the channel raw value. */
    [Description(nick="Update Stride", blurb="The number of samples taken between channel value updates")]
    public int update_stride {
        get { return _update_stride; }
        set { _update_stride = value; }
    }

    /* A vector of the current binary data values of the channels */
    private float [] data_register;

    private Cld.AIChannel [] channel_array;

    /**
     * A signal that starts streaming tasks concurrently.
     */
    public signal void async_start (GLib.DateTime start);

    private int fd = -1;
    private bool channelize = false;

    /**
     * Common construction
     */
    construct {
        id = "mux0";
        fname = "/tmp/fifo-%s".printf (id);
        taskrefs = new Gee.ArrayList<string> ();
    }

    /**
     * Construction using an xml node
     */
    public Cld.Multiplexer.from_xml_node (Xml.Node *node) {
        id = node->get_prop ("id");

        /* Iterate through node children */
        for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {
            if (iter->name == "property") {
                switch (iter->get_prop ("name")) {
                    case "update-stride":
                        update_stride = int.parse (iter->get_content ());
                        break;
                    case "taskref":
                        taskrefs.add (iter->get_content ());
                        break;
                    default:
                        break;
                }
            }
        }

        fname = "/tmp/fifo-%s".printf (id);
    }

    /**
     * Perform additional multiplexer initialization.
     */
    public void generate () {
        int n = 0;
        var tasks = get_object_map (typeof (Cld.ComediTask));

        foreach (var task in tasks.values) {
            n += (task as Cld.ComediTask).get_channels ().size;
        }

        data_register = new float [n];
        channel_array = new Cld.AIChannel [n];

        int i = 0;
        foreach (var task in tasks.values) {
            foreach (var channel in (task as Cld.ComediTask).get_channels ().values) {
                if (channel is Cld.AIChannel) {
                    channel_array [i++] = channel as Cld.AIChannel;
                }
            }
        }
    }

    /**
     * Set a value in the data register.
     */
    public void set_raw (int index, float val) {
        lock (data_register) {
            data_register[index] = val;
        }
    }

    /**
     * Get a value in the data register.
     */
    public float get_raw (int index) {
        float val;

        lock (data_register) {
            val = data_register[index];
        }

        return val;
    }

    /**
     * Start the tasks and stream the data.
     */
    public async void run () {
        var tasks = get_object_map (typeof (Cld.ComediTask));
        var devices = get_object_map (typeof (Cld.ComediDevice));

        foreach (var task in tasks.values) {
            /* Uses a signal to enable concurrent start of streaming tasks */
            async_start.connect ((task as Cld.ComediTask).async_start);
            (task as Cld.ComediTask).run ();
        }

        /* Create the fifo if it doesn't exist */
        if (Posix.access (fname, Posix.F_OK) == -1) {
            int result = Posix.mkfifo (fname, 0777);
            if (result != 0) {
                error ("Context could not create fifo %s\n", fname);
            }
        }

        /* Async tasks require one extra step for a synchronized start. */
        var start = new GLib.DateTime.now_local ();
        async_start (start);

        open_fifo.begin ((obj, res) => {
            /* Get a file descriptor */
            try {
                fd = open_fifo.end (res);
                debug ("Multiplexer with fifo `%s' and fd %d has a reader",
                       fname, fd);
            } catch (ThreadError e) {
                string msg = e.message;
                error (@"Thread error: $msg");
            }
        });

        bg_multiplex_data.begin ((obj, res) => {
            try {
                bg_multiplex_data.end (res);
                debug ("Multiplexer with fifo `%s' data async ended",
                        fname);
            } catch (ThreadError e) {
                string msg = e.message;
                error (@"Thread error: $msg");
            }
        });
    }

    /**
     * Stop the streaming data tasks
     */
    public void stop () {
        var tasks = get_object_map (typeof (Cld.ComediTask));

        foreach (var task in tasks.values) {
            (task as Cld.ComediTask).stop ();
        }
    }

    /**
     * Opens a FIFO for inter-process communication.
     *
     * @param fname The path name of the named pipe
     * @return A file descriptor for the named pipe
     */
    private async int open_fifo () {
        SourceFunc callback = open_fifo.callback;
        GLib.Thread<int> thread = new GLib.Thread<int>.try ("open_fifo", () => {
            GLib.debug ("Multiplexer `%s' waiting for a reader to FIFO `%s'",
                   id, fname);
            fd = Posix.open (fname, Posix.O_WRONLY);
            if (fd == -1) {
                critical ("%s Posix.open error: %d: %s",
                          fname, Posix.errno, Posix.strerror (Posix.errno));
            } else {
                GLib.debug ("Acquisition controller opening FIFO `%s' fd: %d",
                       fname, fd);
            }

            Idle.add ((owned) callback);
            return  0;
        });

        yield;

        return fd;
    }

    /**
     * Multiplexes data from multiple task and writes it to a queue.
     * Also, it writes data to a FIFO for inter-process communication.
     * @param fname The path name of the named pipe.
     */
    private async void bg_multiplex_data () throws ThreadError {
        SourceFunc callback = bg_multiplex_data.callback;
        int buffsz = 1048576;
        int total = 0;
        int i = 0;
        Cld.ComediDevice[] devices;     // the Comedi devices used by these tasks
        Cld.ComediTask[] tasks;
        int[] nchans;                   // the number of channels in each task
        int nchan = 0;                  // the total number of channels in this multiplexer
        int[] subdevices;               // the subdevice numbers for these devices
        int[] buffersizes;              // the data buffer sizes of each subdevice
        int[] buffer_contents;
        int[] nscans;                   // the integral number of scans that are available in a data buffer
        int nscan = int.MAX;            // the integral number of scans that will be multiplexed
        Gee.Deque[] queues;

        var _tasks = get_object_map (typeof (Cld.ComediTask));
        int size = _tasks.size;

        devices = new Cld.ComediDevice[size];
        tasks = new Cld.ComediTask[size];
        nchans = new int[size];
        subdevices = new int[size];
        buffersizes = new int[size];
        buffer_contents = new int[size];
        nscans = new int[size];
        queues = new Gee.Deque<double>[size];

        foreach (var task in _tasks.values) {
            tasks[i] = task as ComediTask;
            devices[i] = (task as ComediTask).device as Cld.ComediDevice;
            nchans[i] = (task as ComediTask).get_channels ().size;
            nchan += nchans[i];
            subdevices[i] = (task as ComediTask).subdevice;
            buffersizes[i] = (devices[i] as Cld.ComediDevice).dev.get_buffer_size (subdevices[i]);
            queues[i] = (task as ComediTask).queue;
            i++;
        }

        GLib.Thread<int> thread = new GLib.Thread<int>.try ("multiplexer_queue_data",  () => {
            while (true) {
                float *value = GLib.malloc (sizeof (float));
                uint8 *data  = GLib.malloc (sizeof (float));
                int64 t = GLib.get_monotonic_time ();
                int total_old = total;

                /* Determine the minimum integral size data required for multiplexing */
                nscan = int.MAX;
                for (i = 0; i < size; i++) {
                    nscans[i] = queues[i].size / nchans[i] ;
                    nscan = nscan < nscans[i] ? nscan : nscans[i];
                }

                /* scans */
                for (i = 0; i < nscan; i++) {

                    int raw_index = 0;      // data register index for channels digital raw value.

                    /* tasks */
                    for (int j = 0; j < size; j++) {
                        /* channels */
                        for (int k = 0; k < nchans[j]; k++) {
                            *value = tasks[j].poll_queue ();
                            Posix.memcpy (data, value, sizeof (float));
                            /* Write the data to the fifo */
                            if (fd != -1) {
                                int ret =  (int)Posix.write (fd, data, sizeof (float));
                                if (ret == -1) {
                                    error ("Posix.errno = %d", Posix.errno);
                                }
                            }

                            /* Write the raw value to a register */
                            lock (data_register) {
                                data_register[raw_index] = *value;
                            }

                            raw_index++;
                            total++;
                            if ((total % (nchan * update_stride)) == 0) {
                                for (int p = 0; p < channel_array.length; p++) {
                                    channel_array [p].add_raw_value
                                                   ((double) data_register [p]);
                                }
                            }
                            /*
                             *if ((total % (nchan * 200)) == 0) {
                             *    debug ("multiplexer: %d %d", Linux.gettid (), total/(nchan * 200));
                             *}
                             */
                        }
                    }
                }
                GLib.free (value);
                GLib.free (data);
            }

            Idle.add ((owned) callback);
            return 0;
        });

        yield;
    }
}

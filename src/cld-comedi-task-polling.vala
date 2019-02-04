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

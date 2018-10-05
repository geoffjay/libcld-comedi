/**
 * Sample program to illustrate polled data acquisition using a Comedi
 * device.
 */

class Cld.PollingExample : Cld.Example {

    public override string xml {
        get { return _xml; }
        set { _xml = value; }
    }

    public GLib.MainLoop loop;
    public AcquisitionController acq;
    public ComediDevice device = new ComediDevice ();
    public Cld.Log log;
    public Cld.ComediTask task;

    construct {
        xml = """
            <cld xmlns:cld="urn:libcld">
                <cld:objects>

                    <cld:object id="daqctl0" type="controller" ctype="acquisition">
                        <cld:object id="dev0" type="device" driver="comedi">
                            <cld:property name="hardware">PCI-1713</cld:property>
                            <cld:property name="type">input</cld:property>
                            <cld:property name="filename">/dev/comedi1</cld:property>
                            <cld:object id="tk0" type="task" ttype="comedi">
                                <cld:property name="exec-type">polling</cld:property>
                                <cld:property name="devref">/ctr0/daqctl0/dev0</cld:property>
                                <cld:property name="subdevice">0</cld:property>
                                <cld:property name="direction">read</cld:property>
                                <cld:property name="interval-ms">10</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai0</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai1</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai2</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai3</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai4</cld:property>
                                <cld:property name="data-cource">channel</cld:property>
                            </cld:object>
                            <cld:object id="ai0" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN0</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">0</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai1" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN1</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">1</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai2" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN2</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">2</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai3" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN3</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">3</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai4" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN4</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">4</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                        </cld:object>
                    </cld:object>

                    <cld:object id="logctl0" type="controller" ctype="log">
                        <cld:object id="log0" type="log" ltype="csv">
                            <cld:property name="title">Data Log</cld:property>
                            <cld:property name="path">/srv/data</cld:property>
                            <cld:property name="file">log.csv</cld:property>
                            <cld:property name="format">%F-%T</cld:property>
                            <cld:property name="rate">10.000</cld:property>
                            <cld:property name="backup-path">./</cld:property>
                            <cld:property name="backup-file">backup.db</cld:property>
                            <cld:property name="backup-interval-hrs">1</cld:property>
                            <cld:property name="data-source">channel</cld:property>
                            <cld:object id="col0" type="column" chref="/ctr0/daqctl0/dev0/ai0"/>
                            <cld:object id="col1" type="column" chref="/ctr0/daqctl0/dev0/ai1"/>
                            <cld:object id="col2" type="column" chref="/ctr0/daqctl0/dev0/ai2"/>
                            <cld:object id="col3" type="column" chref="/ctr0/daqctl0/dev0/ai3"/>
                            <cld:object id="col4" type="column" chref="/ctr0/daqctl0/dev0/ai4"/>
                        </cld:object>
                    </cld:object>

                    <cld:object id="cal0" type="calibration">
                        <cld:property name="units">Volts</cld:property>
                        <cld:object id="cft0" type="coefficient">
                            <cld:property name="n">0</cld:property>
                            <cld:property name="value">0.000</cld:property>
                        </cld:object>
                        <cld:object id="cft1" type="coefficient">
                            <cld:property name="n">1</cld:property>
                            <cld:property name="value">1.000</cld:property>
                        </cld:object>
                    </cld:object>

                </cld:objects>
            </cld>
        """;
    }

    public PollingExample () {

        base ();
        loop = new GLib.MainLoop ();
    }

    public override void run () {

        base.run ();

        //stdout.printf ("\nPrinting objects..\n\n");
        //context.print_objects ();
        //stdout.printf ("\n Finished.\n\n");

        stdout.printf ("\nPrinting reference table..\n\n");
        (context as Cld.Container).print_ref_list ();
        stdout.printf ("\n Finished.\n\n");

        /* Here the device can be accessed without referring to it directly from either its id or uri*/
        var acquisiton_controllers = context.get_children (typeof (AcquisitionController));
        foreach (var ctrl in acquisiton_controllers.values) {
            acq = ctrl as AcquisitionController;
            break; // take the first one.
        }

        var devices = context.get_object_map (typeof (Device));
        foreach (var dev in devices.values) {
            device = dev as ComediDevice;
            break;
        }

        //stdout.printf ("Object properties:\n%s", context.to_string_recursive ());
        device.open ();
        var info = device.info ();
        stdout.printf ("Comedi.Device information:\n%s\n", info.to_string ());

        var tasks = device.get_children (typeof (ComediTask));
        foreach (var tsk in tasks.values) {
            task = tsk as ComediTask;
            break;
        }
        task.run ();

        /* Here the Log is accessed from its uri. */
        //log = context.get_object_from_uri ("/ctr0/logctl0/log0") as Cld.SqliteLog;
        log = context.get_object_from_uri ("/ctr0/logctl0/log0") as Cld.CsvLog;
        log.start ();

        GLib.Timeout.add_seconds (6, quit_cb);
        loop.run ();
    }

    public bool quit_cb () {
        log.stop ();
        task.stop ();
        loop.quit ();

        return false;
    }
}

int main (string[] args) {

    var ex = new Cld.PollingExample ();
    ex.run ();

    return (0);
}

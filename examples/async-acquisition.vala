/**
 * Sample program to illustrate asynchronous data acquisition using a Comedi
 * device.
 */
class Cld.AsyncAcquisitionExample : Cld.Example {

    public override string xml {
        get { return _xml; }
        set { _xml = value; }
    }

    public GLib.MainLoop loop;
    public Cld.AIChannel chan;

    construct {
        xml = """
          <cld xmlns:cld="urn:libcld">
            <cld:objects>
              <cld:object id="daqctl0" type="controller" ctype="acquisition">
                <cld:object id="mux0" type="multiplexer">
                  <cld:property name="taskref">/daqctl0/dev0/tk0</cld:property>
                  <cld:property name="update-stride">4</cld:property>
                </cld:object>
                <cld:object id="dev0" type="device" driver="comedi">
                  <cld:property name="hardware">PCI-1713</cld:property>
                  <cld:property name="type">input</cld:property>
                  <cld:property name="filename">/dev/comedi1</cld:property>
                  <cld:object id="tk0" type="task" ttype="comedi">
                    <cld:property name="exec-type">streaming</cld:property>
                    <cld:property name="devref">/daqctl0/dev0</cld:property>
                    <cld:property name="subdevice">0</cld:property>
                    <cld:property name="direction">read</cld:property>
                    <cld:property name="interval-ns">5000000</cld:property>
                    <cld:property name="resolution-ns">200</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai00</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai01</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai02</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai03</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai04</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai05</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai06</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai07</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai08</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai09</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai10</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai11</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai12</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai13</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai14</cld:property>
                    <cld:property name="chref">/daqctl0/dev0/ai15</cld:property>
                  </cld:object>
                  <cld:object id="ai00" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN0</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">0</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai01" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN1</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">1</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai02" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN2</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">2</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai03" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN3</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">3</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai04" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN4</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">4</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai05" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN5</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">5</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai06" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN6</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">6</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai07" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN7</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">7</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai08" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN8</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">8</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai09" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN9</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">9</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai10" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN10</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">10</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai11" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN11</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">11</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai12" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN12</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">12</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai13" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN13</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">13</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai14" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN14</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">14</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
                  <cld:object id="ai15" type="channel" ref="/daqctl0/dev0" ctype="analog" direction="input">
                    <cld:property name="tag">IN15</cld:property>
                    <cld:property name="desc">Sample Input</cld:property>
                    <cld:property name="num">15</cld:property>
                    <cld:property name="calref">/cal0</cld:property>
                    <cld:property name="range">4</cld:property>
                  </cld:object>
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
              <cld:object id="logctl0" type="controller" ctype="log">
                <cld:object id="log0" type="log" ltype="sqlite">
                  <cld:property name="title">Data Log</cld:property>
                  <cld:property name="path">/tmp</cld:property>
                  <cld:property name="file">log0.db</cld:property>
                  <cld:property name="format">%F-%T</cld:property>
                  <cld:property name="data-source">/daqctl0/mux0</cld:property>
                  <cld:property name="rate">200</cld:property>
                  <cld:object id="col00" type="column" chref="/daqctl0/dev0/ai00"/>
                  <cld:object id="col01" type="column" chref="/daqctl0/dev0/ai01"/>
                  <cld:object id="col02" type="column" chref="/daqctl0/dev0/ai02"/>
                  <cld:object id="col03" type="column" chref="/daqctl0/dev0/ai03"/>
                  <cld:object id="col04" type="column" chref="/daqctl0/dev0/ai04"/>
                  <cld:object id="col05" type="column" chref="/daqctl0/dev0/ai05"/>
                  <cld:object id="col06" type="column" chref="/daqctl0/dev0/ai06"/>
                  <cld:object id="col07" type="column" chref="/daqctl0/dev0/ai07"/>
                  <cld:object id="col08" type="column" chref="/daqctl0/dev0/ai08"/>
                  <cld:object id="col09" type="column" chref="/daqctl0/dev0/ai09"/>
                  <cld:object id="col10" type="column" chref="/daqctl0/dev0/ai10"/>
                  <cld:object id="col11" type="column" chref="/daqctl0/dev0/ai11"/>
                  <cld:object id="col12" type="column" chref="/daqctl0/dev0/ai12"/>
                  <cld:object id="col13" type="column" chref="/daqctl0/dev0/ai13"/>
                  <cld:object id="col14" type="column" chref="/daqctl0/dev0/ai14"/>
                  <cld:object id="col15" type="column" chref="/daqctl0/dev0/ai15"/>
                </cld:object>
              </cld:object>
            </cld:objects>
          </cld>
        """;
    }

    public AsyncAcquisitionExample () {

        base ();
        loop = new GLib.MainLoop ();
    }

    public override void run () {

        base.run ();

        /*
         *stdout.printf ("\nPrinting reference table..\n\n");
         *context.print_ref_list ();
         *stdout.printf ("\n Finished.\n\n");
         */

        /*
         *var device = context.get_object ("dev0") as Cld.ComediDevice;
         *(device as Cld.ComediDevice).open ();
         *var info = device.info ();
         *stdout.printf ("Comedi.Device information:\n%s\n", info.to_string ());
         *GLib.message ("%s", context.get_object ("tk0").to_string ());
         */

        //GLib.message ("%s", context.to_string_recursive ());



        GLib.Timeout.add_seconds (2, start_acq_cb);
        /*
         *GLib.Timeout.add_seconds (5, start_log_cb);
         */
        chan = context.get_object ("ai00") as Cld.AIChannel;
        (chan as Cld.ScalableChannel).new_value.connect ((id, value) => {
            stdout.printf ("ai00: %8.3f\n", chan.scaled_value);
        });

        /*
         *GLib.Timeout.add_seconds (15, stop_log_cb);
         */
        GLib.Timeout.add_seconds (20, stop_acq_cb);
        GLib.Timeout.add_seconds (25, quit_cb);

        loop.run ();
    }

    public bool start_acq_cb () {
        var ctl = context.get_object ("daqctl0");
        (ctl as Cld.AcquisitionController).run ();
        //Cld.SqliteLog log0 = context.get_object_from_uri ("/logctl0/log0") as Cld.SqliteLog;
        //stdout.printf ("Log:\n%s\n", log0.to_string ());
        //log0.start ();

        return false;
    }

    public bool start_log_cb () {
        Cld.SqliteLog log0 = context.get_object_from_uri ("/logctl0/log0") as Cld.SqliteLog;
        stdout.printf ("Log:\n%s\n", log0.to_string ());
        log0.start ();
        return false;
    }

    public bool stop_log_cb () {
        var log0 = context.get_object_from_uri ("/logctl0/log0") as Cld.SqliteLog;
        (log0 as Cld.Log).stop ();
        return false;
    }

    public bool stop_acq_cb () {
        var ctl = context.get_object ("daqctl0");
        (ctl as Cld.AcquisitionController).stop ();
        stdout.printf ("stop_acq_cb ()\n");

        return false;
    }

    public bool quit_cb () {
        var task = context.get_object ("tk0") as Cld.ComediTask;
        var channels = task.get_channels ();
        message ("channels size: %d", channels.size);
        loop.quit ();
        return false;
    }

}

int main (string[] args) {

    var ex = new Cld.AsyncAcquisitionExample ();
    ex.run ();

    return 0;
}

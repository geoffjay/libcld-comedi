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
    public ComediDevice device = new ComediDevice ();
    public Cld.Log log;
    public Cld.ComediTask task;

    construct {
        xml = """
            <cld xmlns:cld="urn:libcld">
                <cld:objects>
                    <cld:object id="daqctl0" type="controller" ctype="acquisition">
                        <cld:object id="mux0" type="multiplexer">
                            <cld:property name="taskref">/ctr0/daqctl0/dev0/tk0</cld:property>
                            <cld:property name="taskref">/ctr0/daqctl0/dev1/tk1</cld:property>
                            <cld:property name="taskref">/ctr0/daqctl0/dev2/tk2</cld:property>
                            <cld:property name="interval-ms">100</cld:property>
                            <cld:property name="fname">/tmp/fifo0</cld:property>
                        </cld:object>
                        <cld:object id="dev0" type="device" driver="comedi">
                            <cld:property name="hardware">PCI-1710</cld:property>
                            <cld:property name="type">input</cld:property>
                            <cld:property name="filename">/dev/comedi0</cld:property>
                            <cld:object id="tk0" type="task" ttype="comedi">
                                <cld:property name="exec-type">streaming</cld:property>
                                <cld:property name="devref">/ctr0/daqctl0/dev0</cld:property>
                                <cld:property name="subdevice">0</cld:property>
                                <cld:property name="direction">read</cld:property>
                                <cld:property name="interval-ns">480000</cld:property>
                                <cld:property name="resolution-ns">200</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai00</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai01</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai02</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai03</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai04</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai05</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai06</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai07</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai08</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai09</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai10</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai11</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai12</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai13</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai14</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev0/ai15</cld:property>
                            </cld:object>
                            <cld:object id="ai00" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN0</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">0</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai01" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN1</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">1</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai02" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN2</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">2</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai03" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN3</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">3</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai04" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN4</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">4</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai05" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN5</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">5</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai06" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN6</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">6</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai07" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN7</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">7</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai08" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN8</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">8</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai09" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN9</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">9</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai10" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN10</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">10</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai11" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN11</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">11</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai12" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN12</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">12</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai13" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN13</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">13</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai14" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN14</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">14</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai15" type="channel" ref="/ctr0/daqctl0/dev0" ctype="analog" direction="input">
                                <cld:property name="tag">IN15</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">15</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                        </cld:object>
                        <cld:object id="dev1" type="device" driver="comedi">
                            <cld:property name="hardware">PCI-1710</cld:property>
                            <cld:property name="type">input</cld:property>
                            <cld:property name="filename">/dev/comedi1</cld:property>
                            <cld:object id="tk1" type="task" ttype="comedi">
                                <cld:property name="exec-type">streaming</cld:property>
                                <cld:property name="devref">/ctr0/daqctl0/dev1</cld:property>
                                <cld:property name="subdevice">0</cld:property>
                                <cld:property name="direction">read</cld:property>
                                <cld:property name="interval-ns">480000</cld:property>
                                <cld:property name="resolution-ns">200</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai00</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai01</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai02</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai03</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai04</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai05</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai06</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai07</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai08</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai09</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai10</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai11</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai12</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai13</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai14</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev1/ai15</cld:property>
                            </cld:object>
                            <cld:object id="ai00" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN0</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">0</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai01" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN1</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">1</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai02" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN2</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">2</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai03" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN3</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">3</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai04" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN4</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">4</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai05" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN5</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">5</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai06" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN6</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">6</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai07" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN7</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">7</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai08" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN8</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">8</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai09" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN9</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">9</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai10" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN10</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">10</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai11" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN11</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">11</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai12" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN12</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">12</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai13" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN13</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">13</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai14" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN14</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">14</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai15" type="channel" ref="/ctr0/daqctl0/dev1" ctype="analog" direction="input">
                                <cld:property name="tag">IN15</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">15</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                        </cld:object>
                        <cld:object id="dev2" type="device" driver="comedi">
                            <cld:property name="hardware">PCI-1710</cld:property>
                            <cld:property name="type">input</cld:property>
                            <cld:property name="filename">/dev/comedi2</cld:property>
                            <cld:object id="tk2" type="task" ttype="comedi">
                                <cld:property name="exec-type">streaming</cld:property>
                                <cld:property name="devref">/ctr0/daqctl0/dev2</cld:property>
                                <cld:property name="subdevice">0</cld:property>
                                <cld:property name="direction">read</cld:property>
                                <cld:property name="interval-ns">480000</cld:property>
                                <cld:property name="resolution-ns">200</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai00</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai01</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai02</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai03</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai04</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai05</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai06</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai07</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai08</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai09</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai10</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai11</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai12</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai13</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai14</cld:property>
                                <cld:property name="chref">/ctr0/daqctl0/dev2/ai15</cld:property>
                            </cld:object>
                            <cld:object id="ai00" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN0</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">0</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai01" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN1</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">1</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai02" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN2</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">2</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai03" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN3</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">3</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai04" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN4</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">4</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai05" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN5</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">5</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai06" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN6</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">6</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai07" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN7</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">7</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai08" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN8</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">8</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai09" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN9</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">9</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai10" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN10</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">10</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai11" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN11</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">11</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai12" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN12</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">12</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai13" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN13</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">13</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai14" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN14</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">14</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                            <cld:object id="ai15" type="channel" ref="/ctr0/daqctl0/dev2" ctype="analog" direction="input">
                                <cld:property name="tag">IN15</cld:property>
                                <cld:property name="desc">Sample Input</cld:property>
                                <cld:property name="num">15</cld:property>
                                <cld:property name="calref">/ctr0/cal0</cld:property>
                                <cld:property name="range">4</cld:property>
                            </cld:object>
                        </cld:object>
                    </cld:object>
                    <cld:object id="logctl0" type="controller" ctype="log">
                        <cld:object id="log0" type="log" ltype="sqlite">
                            <cld:property name="title">Data Log</cld:property>
                            <cld:property name="path">/srv/data</cld:property>
                            <cld:property name="file">log0.db</cld:property>
                            <cld:property name="format">%F-%T</cld:property>
                            <cld:property name="rate">1.000</cld:property>
                            <cld:property name="backup-path">./</cld:property>
                            <cld:property name="backup-file">backup0.db</cld:property>
                            <cld:property name="backup-interval-hrs">1</cld:property>
                            <cld:property name="data-source">fifo</cld:property>
                            <cld:object id="col000" type="column" chref="/ctr0/daqctl0/dev0/ai00"/>
                            <cld:object id="col001" type="column" chref="/ctr0/daqctl0/dev0/ai01"/>
                            <cld:object id="col002" type="column" chref="/ctr0/daqctl0/dev0/ai02"/>
                            <cld:object id="col003" type="column" chref="/ctr0/daqctl0/dev0/ai03"/>
                            <cld:object id="col004" type="column" chref="/ctr0/daqctl0/dev0/ai04"/>
                            <cld:object id="col005" type="column" chref="/ctr0/daqctl0/dev0/ai05"/>
                            <cld:object id="col006" type="column" chref="/ctr0/daqctl0/dev0/ai06"/>
                            <cld:object id="col007" type="column" chref="/ctr0/daqctl0/dev0/ai07"/>
                            <cld:object id="col008" type="column" chref="/ctr0/daqctl0/dev0/ai08"/>
                            <cld:object id="col009" type="column" chref="/ctr0/daqctl0/dev0/ai09"/>
                            <cld:object id="col010" type="column" chref="/ctr0/daqctl0/dev0/ai10"/>
                            <cld:object id="col011" type="column" chref="/ctr0/daqctl0/dev0/ai11"/>
                            <cld:object id="col012" type="column" chref="/ctr0/daqctl0/dev0/ai12"/>
                            <cld:object id="col013" type="column" chref="/ctr0/daqctl0/dev0/ai13"/>
                            <cld:object id="col014" type="column" chref="/ctr0/daqctl0/dev0/ai14"/>
                            <cld:object id="col015" type="column" chref="/ctr0/daqctl0/dev0/ai15"/>
                            <cld:object id="col100" type="column" chref="/ctr0/daqctl0/dev1/ai00"/>
                            <cld:object id="col101" type="column" chref="/ctr0/daqctl0/dev1/ai01"/>
                            <cld:object id="col102" type="column" chref="/ctr0/daqctl0/dev1/ai02"/>
                            <cld:object id="col103" type="column" chref="/ctr0/daqctl0/dev1/ai03"/>
                            <cld:object id="col104" type="column" chref="/ctr0/daqctl0/dev1/ai04"/>
                            <cld:object id="col105" type="column" chref="/ctr0/daqctl0/dev1/ai05"/>
                            <cld:object id="col106" type="column" chref="/ctr0/daqctl0/dev1/ai06"/>
                            <cld:object id="col107" type="column" chref="/ctr0/daqctl0/dev1/ai07"/>
                            <cld:object id="col108" type="column" chref="/ctr0/daqctl0/dev1/ai08"/>
                            <cld:object id="col109" type="column" chref="/ctr0/daqctl0/dev1/ai09"/>
                            <cld:object id="col110" type="column" chref="/ctr0/daqctl0/dev1/ai10"/>
                            <cld:object id="col111" type="column" chref="/ctr0/daqctl0/dev1/ai11"/>
                            <cld:object id="col112" type="column" chref="/ctr0/daqctl0/dev1/ai12"/>
                            <cld:object id="col113" type="column" chref="/ctr0/daqctl0/dev1/ai13"/>
                            <cld:object id="col114" type="column" chref="/ctr0/daqctl0/dev1/ai14"/>
                            <cld:object id="col115" type="column" chref="/ctr0/daqctl0/dev1/ai15"/>
                            <cld:object id="col200" type="column" chref="/ctr0/daqctl0/dev2/ai00"/>
                            <cld:object id="col201" type="column" chref="/ctr0/daqctl0/dev2/ai01"/>
                            <cld:object id="col202" type="column" chref="/ctr0/daqctl0/dev2/ai02"/>
                            <cld:object id="col203" type="column" chref="/ctr0/daqctl0/dev2/ai03"/>
                            <cld:object id="col204" type="column" chref="/ctr0/daqctl0/dev2/ai04"/>
                            <cld:object id="col205" type="column" chref="/ctr0/daqctl0/dev2/ai05"/>
                            <cld:object id="col206" type="column" chref="/ctr0/daqctl0/dev2/ai06"/>
                            <cld:object id="col207" type="column" chref="/ctr0/daqctl0/dev2/ai07"/>
                            <cld:object id="col208" type="column" chref="/ctr0/daqctl0/dev2/ai08"/>
                            <cld:object id="col209" type="column" chref="/ctr0/daqctl0/dev2/ai09"/>
                            <cld:object id="col210" type="column" chref="/ctr0/daqctl0/dev2/ai10"/>
                            <cld:object id="col211" type="column" chref="/ctr0/daqctl0/dev2/ai11"/>
                            <cld:object id="col212" type="column" chref="/ctr0/daqctl0/dev2/ai12"/>
                            <cld:object id="col213" type="column" chref="/ctr0/daqctl0/dev2/ai13"/>
                            <cld:object id="col214" type="column" chref="/ctr0/daqctl0/dev2/ai14"/>
                            <cld:object id="col215" type="column" chref="/ctr0/daqctl0/dev2/ai15"/>
                        </cld:object>
                        <cld:object id="log1" type="log" ltype="sqlite">
                            <cld:property name="title">Data Log</cld:property>
                            <cld:property name="path">/srv/data</cld:property>
                            <cld:property name="file">log1.db</cld:property>
                            <cld:property name="format">%F-%T</cld:property>
                            <cld:property name="rate">10.000</cld:property>
                            <cld:property name="backup-path">./</cld:property>
                            <cld:property name="backup-file">backup1.db</cld:property>
                            <cld:property name="backup-interval-hrs">1</cld:property>
                            <cld:property name="data-source">channel</cld:property>
                            <cld:object id="col000" type="column" chref="/ctr0/daqctl0/dev0/ai00"/>
                            <cld:object id="col001" type="column" chref="/ctr0/daqctl0/dev0/ai01"/>
                            <cld:object id="col002" type="column" chref="/ctr0/daqctl0/dev0/ai02"/>
                            <cld:object id="col003" type="column" chref="/ctr0/daqctl0/dev0/ai03"/>
                            <cld:object id="col004" type="column" chref="/ctr0/daqctl0/dev0/ai04"/>
                            <cld:object id="col005" type="column" chref="/ctr0/daqctl0/dev0/ai05"/>
                            <cld:object id="col006" type="column" chref="/ctr0/daqctl0/dev0/ai06"/>
                            <cld:object id="col007" type="column" chref="/ctr0/daqctl0/dev0/ai07"/>
                            <cld:object id="col008" type="column" chref="/ctr0/daqctl0/dev0/ai08"/>
                            <cld:object id="col009" type="column" chref="/ctr0/daqctl0/dev0/ai09"/>
                            <cld:object id="col010" type="column" chref="/ctr0/daqctl0/dev0/ai10"/>
                            <cld:object id="col011" type="column" chref="/ctr0/daqctl0/dev0/ai11"/>
                            <cld:object id="col012" type="column" chref="/ctr0/daqctl0/dev0/ai12"/>
                            <cld:object id="col013" type="column" chref="/ctr0/daqctl0/dev0/ai13"/>
                            <cld:object id="col014" type="column" chref="/ctr0/daqctl0/dev0/ai14"/>
                            <cld:object id="col015" type="column" chref="/ctr0/daqctl0/dev0/ai15"/>
                            <cld:object id="col100" type="column" chref="/ctr0/daqctl0/dev1/ai00"/>
                            <cld:object id="col101" type="column" chref="/ctr0/daqctl0/dev1/ai01"/>
                            <cld:object id="col102" type="column" chref="/ctr0/daqctl0/dev1/ai02"/>
                            <cld:object id="col103" type="column" chref="/ctr0/daqctl0/dev1/ai03"/>
                            <cld:object id="col104" type="column" chref="/ctr0/daqctl0/dev1/ai04"/>
                            <cld:object id="col105" type="column" chref="/ctr0/daqctl0/dev1/ai05"/>
                            <cld:object id="col106" type="column" chref="/ctr0/daqctl0/dev1/ai06"/>
                            <cld:object id="col107" type="column" chref="/ctr0/daqctl0/dev1/ai07"/>
                            <cld:object id="col108" type="column" chref="/ctr0/daqctl0/dev1/ai08"/>
                            <cld:object id="col109" type="column" chref="/ctr0/daqctl0/dev1/ai09"/>
                            <cld:object id="col110" type="column" chref="/ctr0/daqctl0/dev1/ai10"/>
                            <cld:object id="col111" type="column" chref="/ctr0/daqctl0/dev1/ai11"/>
                            <cld:object id="col112" type="column" chref="/ctr0/daqctl0/dev1/ai12"/>
                            <cld:object id="col113" type="column" chref="/ctr0/daqctl0/dev1/ai13"/>
                            <cld:object id="col114" type="column" chref="/ctr0/daqctl0/dev1/ai14"/>
                            <cld:object id="col115" type="column" chref="/ctr0/daqctl0/dev1/ai15"/>
                            <cld:object id="col200" type="column" chref="/ctr0/daqctl0/dev2/ai00"/>
                            <cld:object id="col201" type="column" chref="/ctr0/daqctl0/dev2/ai01"/>
                            <cld:object id="col202" type="column" chref="/ctr0/daqctl0/dev2/ai02"/>
                            <cld:object id="col203" type="column" chref="/ctr0/daqctl0/dev2/ai03"/>
                            <cld:object id="col204" type="column" chref="/ctr0/daqctl0/dev2/ai04"/>
                            <cld:object id="col205" type="column" chref="/ctr0/daqctl0/dev2/ai05"/>
                            <cld:object id="col206" type="column" chref="/ctr0/daqctl0/dev2/ai06"/>
                            <cld:object id="col207" type="column" chref="/ctr0/daqctl0/dev2/ai07"/>
                            <cld:object id="col208" type="column" chref="/ctr0/daqctl0/dev2/ai08"/>
                            <cld:object id="col209" type="column" chref="/ctr0/daqctl0/dev2/ai09"/>
                            <cld:object id="col210" type="column" chref="/ctr0/daqctl0/dev2/ai10"/>
                            <cld:object id="col211" type="column" chref="/ctr0/daqctl0/dev2/ai11"/>
                            <cld:object id="col212" type="column" chref="/ctr0/daqctl0/dev2/ai12"/>
                            <cld:object id="col213" type="column" chref="/ctr0/daqctl0/dev2/ai13"/>
                            <cld:object id="col214" type="column" chref="/ctr0/daqctl0/dev2/ai14"/>
                            <cld:object id="col215" type="column" chref="/ctr0/daqctl0/dev2/ai15"/>
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

    public AsyncAcquisitionExample () {

        base ();
        loop = new GLib.MainLoop ();
    }

    public override void run () {

        base.run ();

        stdout.printf ("\nPrinting reference table..\n\n");
        context.print_ref_list ();
        stdout.printf ("\n Finished.\n\n");

        for (int i = 0; i < 3; i++) {
            var device = context.get_object ("dev%d".printf (i)) as ComediDevice;
            (device as ComediDevice).open ();
            var info = device.info ();
            stdout.printf ("Comedi.Device information:\n%s\n", info.to_string ());
        }

        GLib.Timeout.add_seconds (2, start_acq_cb);
        GLib.Timeout.add_seconds (1, start_log_cb);
        GLib.Timeout.add_seconds (21, stop_log_cb);
        GLib.Timeout.add_seconds (23, quit_cb);

        loop.run ();
    }

    public bool start_acq_cb () {
        var ctl = context.get_object ("daqctl0");
        (ctl as Cld.AcquisitionController).run ();

        return false;
    }

    public bool start_log_cb () {
        var log0 = context.get_object_from_uri ("/logctl0/log0") as Cld.SqliteLog;
        (log0 as Cld.SqliteLog).fifos.set ("/tmp/fifo0", -1);
        stdout.printf ("Log:\n%s\n", log0.to_string ());
        log0.start ();

        return false;
    }

    public bool stop_log_cb () {
        var log0 = context.get_object_from_uri ("/logctl0/log0") as Cld.SqliteLog;
        (log0 as Cld.Log).stop ();

        return false;
    }

    public bool quit_cb () {
        loop.quit ();
        return false;
    }

}

int main (string[] args) {

    var ex = new Cld.AsyncAcquisitionExample ();
    ex.run ();

    return (0);
}


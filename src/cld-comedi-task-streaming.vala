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

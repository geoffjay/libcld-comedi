public class Cld.Comedi.Factory : GLib.Object, Cld.Factory {

    private static Once<Cld.Comedi.Factory> _instance;

    public static unowned Cld.Comedi.Factory get_default () {
        return _instance.once(() => { return new Cld.Comedi.Factory (); });
    }

    public Cld.Object make_object (Type type)
                                   throws GLib.Error {
        Cld.Object object = null;

        switch (type.name ()) {
            case "CldComediDevice":
                object = new Cld.Comedi.Device ();
                break;
            case "CldComediTask":
                object = new Cld.Comedi.Task ();
                break;
            default:
                throw new Cld.FactoryError.TYPE_NOT_FOUND (
                    _("The type requested is not a known Cld Type"));
        }

        return object;
    }
}

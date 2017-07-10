[DBus (name = "org.halfbaked.Sentech")]
interface Sentech : Object {
    public abstract double exposure_time { get; set; }
    public abstract double gain { get; set; }

    public abstract void acquire (bool state) throws IOError;
    public abstract void capture () throws IOError;
}

public class App : Object {

    private Sentech sentech;

    public App () {
        try {
            sentech = Bus.get_proxy_sync (BusType.SESSION,
                                          "org.halfbaked.Sentech",
                                          "/org/halfbaked/sentech");
        } catch (Error e) {
            critical ("Unable to connect to session: %s", e.message);
        }
    }

    public int run () {
        try {
            debug ("Enable acquire");
            sentech.acquire (true);
            debug ("Wait...");
            Posix.sleep (2);
            debug ("Capture image");
            sentech.exposure_time = 500000.0;
            sentech.gain = 10.0;
            sentech.capture ();
            debug ("Wait...");
            Posix.sleep (2);
            debug ("Capture image");
            sentech.exposure_time = 1000000.0;
            sentech.gain = 20.0;
            sentech.capture ();
            debug ("Wait...");
            Posix.sleep (2);
            debug ("Disable acquire");
            sentech.acquire (false);
        } catch (Error e) {
            critical ("Proxy error: %s", e.message);
        }
        return 0;
    }

    public static int main (string[] args) {
        var app = new App ();
        return app.run ();
    }
}

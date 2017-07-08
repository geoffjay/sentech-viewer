[DBus (name = "org.halfbaked.Sentech")]
interface Sentech : Object {
    public abstract void acquire (bool state);
    public abstract void capture ();
}

public class App : Object {

    private Sentech sentech;

    public App () {
        sentech = Bus.get_proxy_sync (BusType.SESSION,
                                      "org.halfbaked.Sentech",
                                      "/org/halfbaked/sentech");
    }

    public int run () {
        debug ("Enable acquire");
        sentech.acquire (true);
        debug ("Wait...");
        Posix.sleep (5);
        debug ("Capture image");
        sentech.capture ();
        debug ("Wait...");
        Posix.sleep (5);
        debug ("Capture image");
        sentech.capture ();
        debug ("Wait...");
        Posix.sleep (5);
        debug ("Disable acquire");
        sentech.acquire (false);
        return 0;
    }

    public static int main (string[] args) {
        var app = new App ();
        return app.run ();
    }
}

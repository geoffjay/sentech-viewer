public class App : Gtk.Application {

    private SentechWindow window;
    private Arv.Camera camera;

    internal App () {
        Object (application_id: "org.halfbaked.SentechViewer",
                flags: ApplicationFlags.FLAGS_NONE);

        /* Get the camera instance */
        Arv.update_device_list ();
        camera = new Arv.Camera (Arv.get_device_id (0));
    }

    protected override void activate () {
        window = new SentechWindow (this, camera);
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
        window.show_all ();
    }

    protected override void shutdown () {
        debug ("Shutting down Sentech Viewer");
        if (camera != null) {
            camera.stop_acquisition ();
        }
    }

    public void test () {
        var builder = new StringBuilder ();
        int width, height;
        unowned string id = Arv.get_device_id (0);
        (unowned string)[] pixel_formats = camera.get_available_pixel_formats_as_strings ();
        int64[] pixel_format_vals = camera.get_available_pixel_formats ();

        camera.get_sensor_size (out width, out height);

        builder.append ("Testing device " + Arv.get_device_model (0) +
                        " from " + Arv.get_device_vendor (0) + "\n\n");
        builder.append (@"  Device ID: $id\n");
        builder.append (@"  Sensor Size: ($width, $height)\n");
        builder.append ("  Pixel Formats:\n");
        for (int i = 0; i < pixel_formats.length; i++) {
            builder.append_printf ("\t- %s (%d)\n", pixel_formats[i], (int) pixel_format_vals[i]);
        }
        var pixel_format = camera.get_pixel_format ();
        builder.append_printf ("  Current Pixel Format %d\n", (int) pixel_format);

        builder.append ("\n");
        stdout.printf (builder.str);
    }

    public static int main(string[] args) {
        GtkClutter.init (ref args);

        var app = new App ();
        //app.test ();

        return app.run (args);
    }
}

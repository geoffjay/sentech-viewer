public class App : Gtk.Application {

    private SentechWindow window;
    private Arv.Camera camera;
    //private Arv.Stream stream;
    //private int fps = 0;
    //private bool busy = false;

    internal App () {
        Object (application_id: "org.halfbaked.SentechViewer",
                flags: ApplicationFlags.FLAGS_NONE);

        /* Get the camera instance */
        Arv.update_device_list ();
        camera = new Arv.Camera (Arv.get_device_id (0));
    }

    //~App () {
        //if (camera != null) {
            //camera.stop_acquisition ();
        //}
    //}

    protected override void activate () {
        window = new SentechWindow (this, camera);
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
        window.show_all ();

        //if (camera != null) {
            //camera.set_frame_rate (1);
            //uint payload = camera.get_payload ();
            //stream = camera.create_stream (null);

            //if (stream != null) {
                //for (int i = 0; i < 50; i++) {
                    //stream.push_buffer (new Arv.Buffer (payload, null));
                //}

                //camera.start_acquisition ();
                //stream.new_buffer.connect (new_buffer_cb);
                //stream.set_emit_signals (true);
            //}
        //}
    }

    //private void new_buffer_cb () {
        //var buffer = stream.try_pop_buffer ();
        //if (buffer != null && !busy) {
            //busy = true;

            //if (buffer.get_status () == Arv.BufferStatus.SUCCESS) {
                //fps++;
            //}

            //var width = buffer.get_image_width ();
            //var height = buffer.get_image_height ();
            //var data = new uint8[width * height];
            //var rgb = new uint8[width * height * 3];
            //Posix.memcpy (data, buffer.get_data (), width * height);

            //[> Use the GUvc method to convert BA81 to RGB3 <]
            //Uvc.bayer_to_rgb24 (data, rgb, width, height, 3);

            //var pixbuf = new Gdk.Pixbuf.from_data (rgb, Gdk.Colorspace.RGB, false, 8, width, height, width * 3);
            ////window.set_image (pixbuf);
            //window.set_image_data (pixbuf);

            //[> Perform image processing here <]

            //[> XXX Not sure why this is necessary <]
            //stream.push_buffer (buffer);

            //busy = false;
        //}
    //}

    public void test () {
        var builder = new StringBuilder ();
        //int64 min, max;
        int width, height;
        unowned string id = Arv.get_device_id (0);
        (unowned string)[] pixel_formats = camera.get_available_pixel_formats_as_strings ();
        int64[] pixel_format_vals = camera.get_available_pixel_formats ();

        camera.get_sensor_size (out width, out height);

        builder.append ("Testing device " + Arv.get_device_model (0) +
                        " from " + Arv.get_device_vendor (0) + "\n\n");
        builder.append (@"  Device ID: $id\n");
        builder.append (@"  Sensor Size: ($width, $height)\n");
        //builder.append (@"  Zoom: ($min, $max)\n");
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
        app.test ();

        return app.run (args);
    }
}

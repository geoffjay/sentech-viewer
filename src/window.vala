[GtkTemplate (ui="/org/halfbaked/Sentech/window.ui")]
public class SentechWindow : Gtk.ApplicationWindow {

    private Arv.Camera camera;

    private Clutter.Image image;

    //[GtkChild]
    //public Gtk.Image img_capture;

    [GtkChild]
    private Gtk.Viewport viewport;

    [GtkChild]
    private Gtk.HeaderBar header;

    [GtkChild]
    private Gtk.Label lbl_width;

    [GtkChild]
    private Gtk.Label lbl_height;

    [GtkChild]
    private Gtk.Adjustment adj_exposure;

    [GtkChild]
    private Gtk.Adjustment adj_gain;

    public SentechWindow (Gtk.Application application, Arv.Camera camera) {
        Object (application: application);

        this.camera = camera;

        var capture_action = new SimpleAction ("capture", null);
        capture_action.activate.connect (capture_activated_cb);
        application.add_action (capture_action);

        /* Setup interface from camera values */
        header.subtitle = camera.get_model_name ();

        int width, height;
        camera.get_sensor_size (out width, out height);
        lbl_width.label = "%d".printf (width);
        lbl_height.label = "%d".printf (height);

        double exp, exp_min, exp_max;
        exp = camera.get_exposure_time ();
        camera.get_exposure_time_bounds (out exp_min, out exp_max);
        adj_exposure.lower = exp_min;
        adj_exposure.upper = exp_max;
        adj_exposure.value = exp;

        double gain, gain_min, gain_max;
        gain = camera.get_gain ();
        camera.get_gain_bounds (out gain_min, out gain_max);
        adj_gain.lower = gain_min;
        adj_gain.upper = gain_max;
        adj_gain.value = gain;

        var embed = new GtkClutter.Embed ();
        viewport.add (embed);
        var stage = embed.get_stage ();
        image = new Clutter.Image ();
        var actor = new Clutter.Actor ();
        actor.content = image;
        stage.add_child (actor);
        //stage.content = image;
    }

    public void set_image (Gdk.Pixbuf pixbuf) {
        //lock (img_capture) {
            //img_capture.set_from_pixbuf (pixbuf);
        //}
    }

    public void set_image_data (Gdk.Pixbuf pixbuf) {
        lock (image) {
            unowned uint8[] pixels = pixbuf.get_pixels_with_length ();
            assert (pixels.length == pixbuf.width * pixbuf.height * 3);
            /*
             *message ("length: %d", pixels.length);
             *message ("   bps: %d", pixbuf.bits_per_sample);
             *message (" chans: %d", pixbuf.n_channels);
             *message (" alpha: %s", pixbuf.has_alpha.to_string ());
             *message (" width: %d", pixbuf.width);
             *message ("height: %d", pixbuf.height);
             *message ("stride: %d", pixbuf.rowstride);
             */
            try {
                image.set_data (pixels,
                                Cogl.PixelFormat.RGB_888,
                                pixbuf.width,
                                pixbuf.height,
                                pixbuf.rowstride);
            } catch (Error e) {
                critical (e.message);
            }
        }
    }

    private void capture_activated_cb (SimpleAction action, Variant? param) {
/*
 *        var buffer = stream.try_pop_buffer ();
 *        if (buffer != null) {
 *            if (buffer.get_status () == Arv.BufferStatus.SUCCESS) {
 *                fps++;
 *            }
 *
 *            var width = buffer.get_image_width ();
 *            var height = buffer.get_image_height ();
 *            var data = new uint8[width * height];
 *            var rgb = new uint8[width * height * 3];
 *            Posix.memcpy (data, buffer.get_data (), width * height);
 *
 *            [> Use the GUvc method to convert BA81 to RGB3 <]
 *            Uvc.bayer_to_rgb24 (data, rgb, width, height, 3);
 *
 *            var pixbuf = new Gdk.Pixbuf.from_data (rgb, Gdk.Colorspace.RGB, false, 8, width, height, width * 3);
 *            set_image (pixbuf);
 *
 *            [> Perform image processing here <]
 *
 *            [> XXX Not sure why this is necessary <]
 *            stream.push_buffer (buffer);
 *        }
 */
    }

    [GtkCallback]
    private void adj_exposure_value_changed_cb () {
        camera.set_exposure_time (adj_exposure.value);
    }

    [GtkCallback]
    private void adj_gain_value_changed_cb () {
        camera.set_gain (adj_gain.value);
    }
}

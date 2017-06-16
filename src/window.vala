public struct GcFeature {
    public string feature;
    public string name;
    public Type feature_type;

    public GcFeature (string feature, string name, Type feature_type) {
        this.feature = feature;
        this.name = name;
        this.feature_type = feature_type;
    }
}

[GtkTemplate (ui="/org/halfbaked/Sentech/ui/window.ui")]
public class SentechWindow : Gtk.ApplicationWindow {

    private Arv.Camera camera;

    private Arv.Device device;

    private GtkClutter.Embed embed;

    private GcFeature[] features = {
        GcFeature ("PixelCorrectionAllEnabled", "Pixel Correction All", typeof (bool)),
        GcFeature ("PixelCorrectionEnabled", "Pixel Correction Index", typeof (bool))
    };

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
    private Gtk.Label lbl_vendor;

    [GtkChild]
    private Gtk.Label lbl_model;

    [GtkChild]
    private Gtk.Label lbl_dev_id;

    [GtkChild]
    private Gtk.Adjustment adj_exposure;

    [GtkChild]
    private Gtk.Adjustment adj_gain;

    [GtkChild]
    private Gtk.ListBox list;

    [GtkChild]
    private Gtk.SizeGroup size_group;

    public SentechWindow (Gtk.Application application, Arv.Camera camera) {
        Object (application: application);

        this.camera = camera;
        device = camera.get_device ();
        device.set_string_feature_value ("ExposureMode", "Timed");
        device.set_string_feature_value ("BalanceWhiteAuto", "Continuous");

        var capture_action = new SimpleAction ("capture", null);
        capture_action.activate.connect (capture_activated_cb);
        application.add_action (capture_action);

        /* Setup interface from camera values */
        header.subtitle = camera.get_model_name ();

        lbl_model.label = camera.get_model_name ();
        lbl_vendor.label = camera.get_vendor_name ();
        lbl_dev_id.label = camera.get_device_id ();

        int width, height;
        camera.get_sensor_size (out width, out height);
        lbl_width.label = "%d".printf (width);
        lbl_height.label = "%d".printf (height);

        double exp, exp_min, exp_max;
        exp = camera.get_exposure_time ();
        camera.get_exposure_time_bounds (out exp_min, out exp_max);
        adj_exposure.lower = exp_min;
        //adj_exposure.upper = exp_max;
        adj_exposure.upper = 1000000.0;
        adj_exposure.value = exp;

        double gain, gain_min, gain_max;
        gain = camera.get_gain ();
        camera.get_gain_bounds (out gain_min, out gain_max);
        adj_gain.lower = gain_min;
        adj_gain.upper = gain_max;
        adj_gain.value = gain;

        embed = new GtkClutter.Embed ();
        viewport.add (embed);

        /* Add styling */
        try {
            var provider = new Gtk.CssProvider ();
            var file = File.new_for_uri ("resource:///org/halfbaked/Sentech/style.css");
            provider.load_from_file (file);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (),
                                                      provider,
                                                      600);
        } catch (Error e) {
            warning ("Error loading CSS style file: %s", e.message);
        }

        //add_features ();

        /* Because CSS isn't working */
        list.@foreach ((row) => {
            row.height_request = 50;
        });
    }

    private void add_features () {
        foreach (var feature in features) {
            Gtk.Popover popover;
            Gtk.Label lbl_value;
            Gtk.Label lbl_name = new Gtk.Label (feature.name);
            lbl_name.xalign = 0.0f;
            Gtk.Box box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            size_group.add_widget (lbl_name);
            box.add (lbl_name);
            if (feature.feature_type == typeof (bool)) {
                var value = device.get_boolean_feature_value (feature.feature);
                lbl_value = new Gtk.Label (value.to_string ());
                lbl_value.expand = true;
                lbl_value.justify = Gtk.Justification.RIGHT;
                lbl_value.xalign = 1.0f;
                lbl_value.xpad = 5;
                popover = new GcBooleanEdit ();
                popover.relative_to = lbl_value;
                lbl_value.button_release_event.connect ((event) => {
                    message ("suck it trebek!");
                    popover.popup ();
                    return false;
                });
                (popover as GcBooleanEdit).btn_value.active = value;
                popover.closed.connect (() => {
                    lbl_value.label = (popover as GcBooleanEdit).btn_value.active.to_string ();
                });
                box.add (lbl_value);
            } else if (feature.feature_type == typeof (float)) {
            } else if (feature.feature_type == typeof (int)) {
            } else if (feature.feature_type == typeof (string)) {
            } else {
                /* Assume enum if nothing else */
            }
            list.add (box);
        }
    }

    public void set_image (Gdk.Pixbuf pixbuf) {
        //lock (img_capture) {
            //img_capture.set_from_pixbuf (pixbuf);
        //}
    }

    public void set_image_data (Gdk.Pixbuf pixbuf) {
        var image = new Clutter.Image ();
            try {
                image.set_data (pixbuf.get_pixels (),
                                Cogl.PixelFormat.RGB_888,
                                pixbuf.width,
                                pixbuf.height,
                                pixbuf.rowstride);
            } catch (Error e) {
                critical (e.message);
            }
        //}
        var stage = embed.get_stage ();
        stage.content = image;
    }

    private void capture_activated_cb (SimpleAction action, Variant? param) {
        var exp_mode = device.get_string_feature_value ("ExposureMode");
        var exp_time = device.get_float_feature_value ("ExposureTime");
        var exp_auto = device.get_boolean_feature_value ("ExposureAuto");
        stdout.printf ("Exposure mode: %s\n", exp_mode);
        stdout.printf ("Exposure time: %f\n", exp_time);
        stdout.printf ("Exposure auto: %s\n", exp_auto.to_string ());
        var bal_lev = device.get_float_feature_value ("BalanceLevel");
        var bal_rat = device.get_float_feature_value ("BalanceRatio");
        var bal_auto = device.get_boolean_feature_value ("BalanceWhiteAuto");
        stdout.printf ("Balance level: %f\n", bal_lev);
        stdout.printf ("Balance ratio: %f\n", bal_rat);
        stdout.printf ("Balance auto: %s\n", bal_auto.to_string ());
        var wb_enum = device.get_available_enumeration_feature_values_as_strings ("BalanceWhiteAuto");
        foreach (var val in wb_enum) {
            stdout.printf (" > %s\n", val);
        }

        //var buffer = stream.try_pop_buffer ();
        var buffer = camera.acquisition (0);
        if (buffer != null) {
            /*
             *if (buffer.get_status () == Arv.BufferStatus.SUCCESS) {
             *    fps++;
             *}
             */

            var width = buffer.get_image_width ();
            var height = buffer.get_image_height ();
            var data = new uint8[width * height];
            var rgb = new uint8[width * height * 3];
            Posix.memcpy (data, buffer.get_data (), width * height);

            /* Use the GUvc method to convert BA81 to RGB3 */
            Uvc.bayer_to_rgb24 (data, rgb, width, height, 3);

            var pixbuf = new Gdk.Pixbuf.from_data (rgb, Gdk.Colorspace.RGB, false, 8, width, height, width * 3);
            set_image_data (pixbuf);

            /* Perform image processing here */

            /* XXX Not sure why this is necessary */
            //stream.push_buffer (buffer);
        }
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

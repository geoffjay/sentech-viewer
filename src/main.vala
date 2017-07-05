public class App : Gtk.Application {

    private static string? opt_debug = null;
    private static string? opt_name = null;
    private static uint opt_packet_timeout = 20;
    private static uint opt_frame_retention = 100;

    const OptionEntry[] options = {
        { "debug", 'd', 0, OptionArg.STRING, ref opt_debug, "Debug domains", null },
        { "name", 'n', 0, OptionArg.STRING, ref opt_name, "Camera name", null },
        { "packet-timeout", 'p',  0, OptionArg.INT, ref opt_packet_timeout, "Packet timeout (ms)", null },
        { "frame-retention", 'm', 0, OptionArg.INT, ref opt_frame_retention, "Frame retention (ms)", null },
        { null }
    };

    private SentechWindow window;
    private Arv.Camera camera;
    private Arv.Stream stream;
    private int buffer_count = 0;

    internal App () {
        Object (application_id: "org.halfbaked.SentechViewer",
                flags: ApplicationFlags.FLAGS_NONE);

        /* Get the camera instance */
        //Arv.update_device_list ();
        if (opt_name == null) {
            debug ("Looking for the first available camera");
        } else {
            debug ("Looking for camera '%s'", opt_name);
        }

        camera = new Arv.Camera (null);

        if (camera != null) {
            init_camera ();
            init_stream ();

            /* Add application actions */
            var capture_action = new SimpleAction ("capture", null);
            capture_action.activate.connect (capture_activated_cb);
            add_action (capture_action);

            var acquire_action = new SimpleAction.stateful ("acquire", null, new Variant.boolean (false));
            acquire_action.activate.connect (acquire_activated_cb);
            add_action (acquire_action);
        } else {
            critical ("No camera was found");
        }
    }

    protected override void activate () {
        window = new SentechWindow (this, camera);
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
        window.show_all ();
    }

    protected override void shutdown () {
        var builder = new StringBuilder ();
        uint64 n_completed_buffers, n_failures, n_underruns;

        if (stream != null) {
            stream.get_statistics (out n_completed_buffers, out n_failures, out n_underruns);
            builder.append_printf ("Completed buffers .. %Lu\n", n_completed_buffers);
            builder.append_printf ("Failures ........... %Lu\n", n_failures);
            builder.append_printf ("Underruns .......... %Lu", n_underruns);
            debug ("\n\n%s", builder.str);
        }

        if (camera != null) {
            camera.stop_acquisition ();
        }

        base.shutdown ();
    }

    private void init_camera () {
        var builder = new StringBuilder ();
        uint payload;
        int x, y, width, height;
        int dx, dy;
        double exposure;
        double gain;

        camera.get_region (out x, out y, out width, out height);
        camera.get_binning (out dx, out dy);
        exposure = camera.get_exposure_time ();
        payload = camera.get_payload ();
        gain = camera.get_gain ();

        builder.append_printf ("vendor name: ........... %s\n", camera.get_vendor_name ());
        builder.append_printf ("model name: ............ %s\n", camera.get_model_name ());
        builder.append_printf ("device id: ............. %s\n", camera.get_device_id ());
        builder.append_printf ("image width: ........... %d\n", width);
        builder.append_printf ("image height: .......... %d\n", height);
        builder.append_printf ("horizontal binning: .... %d\n", dx);
        builder.append_printf ("vertical binning: ...... %d\n", dy);
        builder.append_printf ("payload: ............... %u bytes\n", payload);
        builder.append_printf ("exposure: .............. %g us\n", exposure);
        builder.append_printf ("gain: .................. %g dB\n", gain);

        if (camera.is_gv_device ()) {
            builder.append_printf ("gv n_stream channels: .. %d\n", camera.gv_get_n_stream_channels ());
            builder.append_printf ("gv current channel: .... %d\n", camera.gv_get_current_stream_channel ());
            builder.append_printf ("gv packet delay: ....... %L ns\n", camera.gv_get_packet_delay ());
            builder.append_printf ("gv packet size: ........ %u bytes\n", camera.gv_get_packet_size ());
        }

        /*
         *[> Doesn't work with Aravis < 0.6.0 <]
         *if (camera.is_uv_device ()) {
         *    uint min, max;
         *    camera.uv_get_bandwidth_bounds (out min, out max);
         *    builder.append_printf ("uv bandwidth limit: .... %u [%u..%u]\n", camera.uv_get_bandwidth (), min, max);
         *}
         */

        debug ("\n\n%s", builder.str);
    }

    private void init_stream () {
        camera.set_frame_rate (1);
        uint payload = camera.get_payload ();
        stream = camera.create_stream (stream_cb);

        if (stream != null) {
            if (stream is Arv.GvStream) {
                (stream as Arv.GvStream).packet_timeout = opt_packet_timeout * 1000;
                (stream as Arv.GvStream).frame_retention = opt_frame_retention * 1000;
            }

            for (int i = 0; i < 50; i++) {
                stream.push_buffer (new Arv.Buffer (payload, null));
            }

            camera.set_acquisition_mode (Arv.AcquisitionMode.CONTINUOUS);

            camera.start_acquisition ();
            stream.new_buffer.connect (new_buffer_cb);
            stream.set_emit_signals (true);
            Timeout.add_seconds (1, periodic_task_cb);
        } else {
            critical ("Unable to initialize stream");
        }
    }

    private void stream_cb (Arv.StreamCallbackType type, Arv.Buffer buffer) {
        if (type == Arv.StreamCallbackType.INIT) {
            if (!Arv.make_thread_high_priority (-10)) {
                warning ("Failed to make stream thread high priority");
            }
        }
    }

    private void new_buffer_cb () {
        var buffer = stream.try_pop_buffer ();
        if (buffer != null) {
            if (buffer.get_status () == Arv.BufferStatus.SUCCESS) {
                buffer_count++;
            }

            var width = buffer.get_image_width ();
            var height = buffer.get_image_height ();
            var data = new uint8[width * height];
            var rgb = new uint8[width * height * 3];
            Posix.memcpy (data, buffer.get_data (), width * height);

            /* Use the GUvc method to convert BA81 to RGB3 */
            Uvc.bayer_to_rgb24 (data, rgb, width, height, 3);

            /*
             *var pixbuf = new Gdk.Pixbuf.from_data (rgb, Gdk.Colorspace.RGB, false, 8, width, height, width * 3);
             *window.set_image (pixbuf);
             */

            stream.push_buffer (buffer);
        }
    }

    private bool periodic_task_cb () {
        debug ("Frame rate: .. %d Hz", buffer_count);
        buffer_count = 0;

        return true;
    }

    private void acquire_activated_cb (SimpleAction action, Variant? param) {
        this.hold ();
        Variant state = action.get_state ();
        bool active = state.get_boolean ();
        action.set_state (new Variant.boolean (!active));

        if (!active) {
            debug ("Activating camera acquisition");
        } else {
            debug ("Deactivating camera acquisition");
        }
        this.release ();
    }

    private void capture_activated_cb (SimpleAction action, Variant? param) {
        var device = camera.get_device ();

        var exp_mode = device.get_string_feature_value ("ExposureMode");
        var exp_time = device.get_float_feature_value ("ExposureTime");
        stdout.printf ("Exposure mode: %s\n", exp_mode);
        stdout.printf ("Exposure time: %f\n", exp_time);
        /*
         *[> Doesn't work in Aravis < 0.6.0 <]
         *var exp_auto = device.get_boolean_feature_value ("ExposureAuto");
         *stdout.printf ("Exposure auto: %s\n", exp_auto.to_string ());
         */
        var bal_lev = device.get_float_feature_value ("BalanceLevel");
        var bal_rat = device.get_float_feature_value ("BalanceRatio");
        stdout.printf ("Balance level: %f\n", bal_lev);
        stdout.printf ("Balance ratio: %f\n", bal_rat);
        /*
         *[> Doesn't work in Aravis < 0.6.0 <]
         *var bal_auto = device.get_boolean_feature_value ("BalanceWhiteAuto");
         *stdout.printf ("Balance auto: %s\n", bal_auto.to_string ());
         */
        var wb_enum = device.get_available_enumeration_feature_values_as_strings ("BalanceWhiteAuto");
        foreach (var val in wb_enum) {
            stdout.printf (" > %s\n", val);
        }

        Arv.Buffer buffer = stream.try_pop_buffer ();
        //var buffer = camera.acquisition (1000000);
        if (buffer != null) {
            if (buffer.get_status () == Arv.BufferStatus.SUCCESS) {
                //fps++;
                debug ("Successfully read buffer");
            }

            var width = buffer.get_image_width ();
            var height = buffer.get_image_height ();
            var data = new uint8[width * height];
            var rgb = new uint8[width * height * 3];
            Posix.memcpy (data, buffer.get_data (), width * height);

            /* Use the GUvc method to convert BA81 to RGB3 */
            Uvc.bayer_to_rgb24 (data, rgb, width, height, 3);

            var pixbuf = new Gdk.Pixbuf.from_data (rgb, Gdk.Colorspace.RGB, false, 8, width, height, width * 3);
            window.set_image (pixbuf);

            /* Perform image processing here */

            /* XXX Not sure why this is necessary */
            stream.push_buffer (buffer);
        }
    }

    public static int main(string[] args) {
        GtkClutter.init (ref args);

        var context = new OptionContext ("sentech-viewer");
        context.set_ignore_unknown_options (true);
        context.set_help_enabled (true);
        context.add_main_entries (options, null);

        try {
            context.parse (ref args);
        } catch (OptionError e) {
            critical (e.message);
        }

        Arv.debug_enable (opt_debug);

        var app = new App ();

        return app.run (args);
    }
}

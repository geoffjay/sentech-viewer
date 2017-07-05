/**
 * This is a non-OOP approach, it's just a copy of the C sample application
 * to debug an issue that isn't there in the test program.
 */
public class App : Object {

    private static string? opt_debug_domains = null;
    private static string? opt_camera_name = null;
    private static bool opt_snapshot = false;
    private static string opt_trigger = null;
    private static double opt_software_trigger = -1.0;
    private static double opt_frequency = -1.0;
    private static int opt_width = -1;
    private static int opt_height = -1;
    private static int opt_horizontal_binning = -1;
    private static int opt_vertical_binning = -1;
    private static double opt_exposure_time_us = -1.0;
    private static int opt_gain = -1;
    private static bool opt_auto_socket_buffer = false;
    private static bool opt_no_packet_resend = false;
    private static uint opt_packet_timeout = 20;
    private static uint opt_frame_retention = 100;
    private static int opt_gv_stream_channel = -1;
    private static int opt_gv_packet_delay = -1;
    private static int opt_gv_packet_size = -1;
    private static bool opt_realtime = false;
    private static bool opt_high_priority = false;
    private static bool opt_no_packet_socket = false;
    private static string? opt_chunks = null;
    private static uint opt_bandwidth_limit = -1;

    const OptionEntry[] options = {
        { null }
    };

    public Arv.Camera camera;
    public Arv.Stream stream;
    public MainLoop main_loop;
    public int buffer_count;
    public Arv.ChunkParser chunk_parser;
    public string[] chunks;

    private static bool cancel = false;

    public App () {
        camera = new Arv.Camera (opt_camera_name);
    }

    public void set_cancel (int signal) {
        cancel = true;
    }

    public void new_buffer_cb () {
        Arv.Buffer buffer;

        buffer = stream.try_pop_buffer ();
        if (buffer != null) {
            if (buffer.get_status () == Arv.BufferStatus.SUCCESS) {
                buffer_count++;
            }

            if (buffer.get_payload_type () == Arv.BufferPayloadType.CHUNK_DATA &&
                chunks != null) {
                for (int i = 0; chunks[i] != null; i++) {
                    stdout.printf ("%s = %L\n", chunks[i], chunk_parser.get_integer_value (buffer, chunks[i]));
                }
            }

            /* Image processing here */

            stream.push_buffer (buffer);
        }
    }

    public void stream_cb (Arv.StreamCallbackType type, Arv.Buffer buffer) {
        if (type == Arv.StreamCallbackType.INIT) {
            if (opt_realtime) {
                if (!Arv.make_thread_realtime (10)) {
                    stdout.printf ("Failed to make stream thread realtime\n");
                }
            } else if (opt_high_priority) {
                if (!Arv.make_thread_high_priority (-10)) {
                    stdout.printf ("Failed to make stream thread high priority\n");
                }
            }
        }
    }

    public bool periodic_task_cb () {
        stdout.printf ("Frame rate = %d Hz\n\n", buffer_count);
        buffer_count = 0;

        if (cancel) {
            main_loop.quit ();
            return false;
        }

        return true;
    }

    public bool emit_software_trigger () {
        camera.software_trigger ();
        return true;
    }

    public void control_lost_cb () {
        stdout.printf ("Control lost\n");
        cancel = true;
    }

    public static int main (string[] args) {

        var context = new OptionContext ("arv-camera-test");
        context.add_main_entries (options, null);

        try {
            context.parse (ref args);
        } catch (OptionError e) {
            critical ("Option parsing failed: %s", e.message);
            return -1;
        }

        Arv.debug_enable (opt_debug_domains);

        if (opt_camera_name == null) {
            stdout.printf ("Looking for the first available camera");
        } else {
            stdout.printf ("Looking for camera '%s'", opt_camera_name);
        }

        var app = new App ();

        app.buffer_count = 0;
        app.chunks = null;
        app.chunk_parser = null;

        if (app.camera != null) {
            /*
             *Posix.sighandler_t old_sigint_handler;
             */
            int payload;
            int x, y, width, height;
            int dx, dy;
            double exposure;
            uint64 n_completed_buffers;
            uint64 n_failures;
            uint64 n_underruns;
            int gain;
            uint software_trigger_source = 0;

            /* Camera setup --- */

            if (opt_chunks != null) {
                debug ("Setup chunks");
                string striped_chunks = GLib.strdup (opt_chunks);
                /* string utilities in Arv didn't make it into the vapi */
                //Arv.str_strip (striped_chunks, " ,:;", ',');
                striped_chunks = striped_chunks.strip ();
                app.chunks = striped_chunks.split_set (",", -1);
                striped_chunks = null;

                app.chunk_parser = app.camera.create_chunk_parser ();

                for (int i = 0; app.chunks[i] != null; i++) {
                    string chunk = "Chunk%s".printf (app.chunks[i]);
                    app.chunks[i] = null;
                    app.chunks[i] = chunk;
                }
            }

            app.camera.set_chunks (opt_chunks);
            app.camera.set_region (0, 0, opt_width, opt_height);
            /*
             *[> Doesn't work in < 0.6.0 <]
             *app.camera.set_binning (opt_horizontal_binning, opt_vertical_binning);
             */
            app.camera.set_exposure_time (opt_exposure_time_us);
            app.camera.set_gain (opt_gain);

            /*
             *[> Doesn't work in < 0.6.0 <]
             *if (app.camera.is_uv_device ()) {
             *    app.camera.uv_set_bandwidth (opt_bandwidth_limit);
             *}
             */

            if (app.camera.is_gv_device ()) {
                app.camera.gv_select_stream_channel (opt_gv_stream_channel);
                app.camera.gv_set_packet_delay (opt_gv_packet_delay);
                app.camera.gv_set_packet_size (opt_gv_packet_size);
                /*
                 *[> Doesn't work in < 0.6.0 <]
                 *app.camera.gv_set_stream_options (opt_no_packet_socket ?
                 *                                  Arv.GvStreamOption.PACKET_SOCKET_DISABLED :
                 *                                  Arv.GvStreamOption.NONE);
                 */
            }

            /* Camera validation --- */

            app.camera.get_region (out x, out y, out width, out height);
            app.camera.get_binning (out dx, out dy);
            exposure = app.camera.get_exposure_time ();
            payload = (int) app.camera.get_payload ();
            gain = (int) app.camera.get_gain ();

            stdout.printf ("vendor name           = %s\n", app.camera.get_vendor_name ());
            stdout.printf ("model name            = %s\n", app.camera.get_model_name ());
            stdout.printf ("device id             = %s\n", app.camera.get_device_id ());
            stdout.printf ("image width           = %d\n", width);
            stdout.printf ("image height          = %d\n", height);
            stdout.printf ("horizontal binning    = %d\n", dx);
            stdout.printf ("vertical binning      = %d\n", dy);
            stdout.printf ("payload               = %d bytes\n", payload);
            stdout.printf ("exposure              = %g µs\n", exposure);
            stdout.printf ("gain                  = %d dB\n", gain);

            if (app.camera.is_gv_device ()) {
                stdout.printf ("gv n_stream channels  = %d\n", app.camera.gv_get_n_stream_channels ());
                stdout.printf ("gv current channel    = %d\n", app.camera.gv_get_current_stream_channel ());
                stdout.printf ("gv packet delay       = %L ns\n", app.camera.gv_get_packet_delay ());
                stdout.printf ("gv packet size        = %d bytes\n", (int) app.camera.gv_get_packet_size ());
            }

/*
 *            [> Doesn't work in < 0.6.0 <]
 *            if (app.camera.is_uv_device ()) {
 *                uint min,max;
 *
 *                app.camera.uv_get_bandwidth_bounds (out min, out max);
 *                stdout.printf ("uv bandwidth limit     = %d [%d..%d]\n",
 *                               (int) app.camera.uv_get_bandwidth (),
 *                               (int) min,
 *                               (int) max);
 *            }
 */

            /* Stream buffer frames --- */

            app.stream = app.camera.create_stream (app.stream_cb);
            if (app.stream != null) {
                if (app.stream is Arv.GvStream) {
                    if (opt_auto_socket_buffer) {
                        (app.stream as Arv.GvStream).socket_buffer = Arv.GvStreamSocketBuffer.AUTO;
                        (app.stream as Arv.GvStream).socket_buffer_size = 0;
                    }

                    if (opt_no_packet_resend) {
                        (app.stream as Arv.GvStream).packet_resend = Arv.GvStreamPacketResend.NEVER;
                    }

                    (app.stream as Arv.GvStream).packet_timeout = opt_packet_timeout * 1000;
                    (app.stream as Arv.GvStream).frame_retention = opt_frame_retention * 1000;
                }

                for (int i = 0; i < 50; i++) {
                    app.stream.push_buffer (new Arv.Buffer (payload, null));
                }

                app.camera.set_acquisition_mode (Arv.AcquisitionMode.CONTINUOUS);

                if (opt_frequency > 0.0) {
                    app.camera.set_frame_rate (opt_frequency);
                }

                if (opt_trigger != null) {
                    app.camera.set_trigger (opt_trigger);
                }

                if (opt_software_trigger > 0.0) {
                    app.camera.set_trigger ("Software");
                    software_trigger_source = Timeout.add ((uint) (0.5 + 1000.0 /
                                                                   opt_software_trigger),
                                                           app.emit_software_trigger);
                }

                app.camera.start_acquisition ();

                app.stream.new_buffer.connect (app.new_buffer_cb);
                app.stream.set_emit_signals (true);

                var device = app.camera.get_device ();
                device.control_lost.connect (app.control_lost_cb);

                Timeout.add_seconds (1, app.periodic_task_cb);

                app.main_loop = new MainLoop ();

                /*
                 *old_sigint_handler = Posix.@signal (Posix.SIGINT, (Posix.sighandler_t) app.set_cancel);
                 */

                Unix.signal_add (Posix.SIGINT, (SourceFunc) app.set_cancel);

                app.main_loop.run ();

                if (software_trigger_source > 0) {
                    Source.remove (software_trigger_source);
                }

                /*
                 *Posix.@signal (Posix.SIGINT, old_sigint_handler);
                 */

                app.main_loop = null;

                app.stream.get_statistics (out n_completed_buffers, out n_failures, out n_underruns);

                stdout.printf ("Completed buffers = %Lu\n", (ulong) n_completed_buffers);
                stdout.printf ("Failures          = %Lu\n", (ulong) n_failures);
                stdout.printf ("Underruns         = %Lu\n", (ulong) n_underruns);

                app.camera.stop_acquisition ();

                app.stream.set_emit_signals (false);

                app.stream = null;
            } else {
                stderr.printf ("Can't create stream thread (check if the device is not already used)\n");
            }

            app.camera = null;
        } else {
            stderr.printf ("No camera found\n");
        }

        return 0;
    }
}

/**
 * Three step process because I can't figure out single step.
 *
 * glib-compile-resources --target=resources.c --generate-source sentech.gresource.xml
 *
 * valac --target-glib=2.38 --vapidir=../../vapi/ --pkg aravis --pkg gio-2.0 \
 *   --pkg gdk-3.0 --pkg gtk+-3.0 --pkg posix --gresources=sentech.gresource.xml \
 *   -C sentech-test.vala window.vala colorspaces.c
 *
 * gcc -o sentech-test `pkg-config --cflags --libs aravis-0.6 gio-2.0 gdk-3.0 gtk+-3.0` \
 *   sentech-test.c window.c colorspaces.c resources.c
 */
public class App : Gtk.Application {

    private SentechWindow window;
    private Arv.Camera camera;
    private Arv.Stream stream;
    private Arv.Device device;
    //private Gtk.Image image;
    private bool cancel = false;
    private int fps = 0;
    private uint8[] rgb;
    private uint8[] data;
    private int width;
    private int height;

    public App () {
        Object (application_id: "org.coanda.sentech",
                flags: ApplicationFlags.FLAGS_NONE);

        /* Get the camera instance */
        Arv.update_device_list ();
        camera = new Arv.Camera (Arv.get_device_id (0));
        camera.get_sensor_size (out width, out height);
        data = new uint8[width * height];
        rgb = new uint8[width * height * 3];

        Unix.signal_add (Posix.SIGINT, () => {
            cancel = true;
            return true;
        });
    }

    ~App () {
        if (camera != null) {
            camera.stop_acquisition ();
        }
    }

    protected override void activate () {
        window = new SentechWindow (this);
        window.show_all ();

        if (camera != null) {
            camera.set_frame_rate (1);
            uint payload = camera.get_payload ();
            stream = camera.create_stream (null);
            device = camera.get_device ();

            if (stream != null) {
                for (int i = 0; i < 50; i++) {
                    stream.push_buffer (new Arv.Buffer (payload, null));
                }

                camera.start_acquisition ();
                stream.new_buffer.connect (new_buffer_cb);
                stream.set_emit_signals (true);
            }
        }
    }

    private void new_buffer_cb () {
        var buffer = stream.try_pop_buffer ();
        if (buffer != null) {
            if (buffer.get_status () == Arv.BufferStatus.SUCCESS) {
                fps++;
            }

            width = buffer.get_image_width ();
            height = buffer.get_image_height ();
            Posix.memcpy (data, buffer.get_data (), width * height);

            /* Use the GUvc method to convert BA81 to RGB3 */
            Uvc.bayer_to_rgb24 (data, rgb, width, height, 3);

            var pixbuf = new Gdk.Pixbuf.from_data (rgb, Gdk.Colorspace.RGB, false, 8, width, height, width * 3);
            window.img_capture.set_from_pixbuf (pixbuf);
            window.img_capture.queue_draw ();

            /* Perform image processing here */

            /* XXX Not sure why this is necessary */
            stream.push_buffer (buffer);
        }
    }

    public void test () {
        var builder = new StringBuilder ();
        //int64 min, max;
        int width, height;
        unowned string id = Arv.get_device_id (0);
        (unowned string)[] pixel_formats = camera.get_available_pixel_formats_as_strings ();
        int64[] pixel_format_vals = camera.get_available_pixel_formats ();

        camera.get_sensor_size (out width, out height);
        //device.get_integer_feature_bounds ("Zoom", out min, out max);

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
        var app = new App ();
        app.test ();

        return app.run (args);
    }
}

namespace Uvc {
    extern void bayer_to_rgb24([CCode (array_length = false)]
                               uint8[] pBay,
                               [CCode (array_length = false)]
                               uint8[] pRGB24,
                               int width, int height, int pix_order);
}

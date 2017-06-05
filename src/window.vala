[GtkTemplate (ui="/org/coanda/Sentech/window.ui")]
public class SentechWindow : Gtk.ApplicationWindow {

    private Arv.Camera camera;

    [GtkChild]
    public Gtk.Image img_capture;

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
    }

    private void display_error (string message) {
        var dialog = new Gtk.MessageDialog (this,
                                            Gtk.DialogFlags.MODAL,
                                            Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.OK,
                                            message);
        dialog.response.connect ((response_id) => {
            debug ("Error acknowledged");
            dialog.destroy ();
            return;
        });
        dialog.show ();
    }

    public void set_image (Gdk.Pixbuf pixbuf) {
        lock (img_capture) {
            img_capture.set_from_pixbuf (pixbuf);
        }
    }

    private void capture_activated_cb (SimpleAction action, Variant? param) {
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

[GtkTemplate (ui="/org/coanda/Sentech/window.ui")]
public class SentechWindow : Gtk.ApplicationWindow {

    [GtkChild]
    public Gtk.Image img_capture;

    public SentechWindow (Gtk.Application application) {
        Object (application: application);
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
}

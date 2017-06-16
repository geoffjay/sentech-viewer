[GtkTemplate (ui="/org/halfbaked/Sentech/ui/gc-boolean-edit.ui")]
public class GcBooleanEdit : Gtk.Popover {

    [GtkChild]
    public Gtk.ToggleButton btn_value;

    [GtkCallback]
    private void btn_value_toggled_cb () {
        if (btn_value.active) {
            debug ("activated");
        } else {
            debug ("deactivated");
        }
    }
}


namespace PixelSaver {

public class Plugin : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new Applet(uuid);
    }
}

public class Applet : Budgie.Applet
{
    Gtk.Label label;
    Gtk.Button minimize_button;
    Gtk.Button maximize_button;
    Gtk.Button close_button;
    Gtk.Image maximize_image;
    Gtk.Image restore_image;

    public string uuid { public set; public get; }

    private Settings? settings;


    public Applet(string uuid)
    {
        Object(uuid: uuid);

        this.minimize_button = new Gtk.Button.from_icon_name ("window-minimize-symbolic");
        this.maximize_button = new Gtk.Button.from_icon_name ("window-maximize-symbolic");
        this.close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.BUTTON);

        this.maximize_image = new Gtk.Image.from_icon_name ("window-maximize-symbolic", Gtk.IconSize.BUTTON);
        this.restore_image = new Gtk.Image.from_icon_name ("window-restore-symbolic", Gtk.IconSize.BUTTON);


        this.label = new Gtk.Label ("");
        this.label.set_ellipsize (Pango.EllipsizeMode.END);
        this.label.set_alignment(0, 0.5f);

        Gtk.EventBox event_box = new Gtk.EventBox();
        event_box.add(this.label);

        Gtk.Box box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.pack_start (event_box, false, false, 0);
        box.pack_start (this.minimize_button, false, false, 0);
        box.pack_start (this.maximize_button, false, false, 0);
        box.pack_start (this.close_button, false, false, 0);
        this.add (box);


        event_box.button_press_event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS){
                PixelSaver.TitleBarManager.INSTANCE.toggle_maximize_active_window();
            }
            return Gdk.EVENT_PROPAGATE;
        });

        this.minimize_button.clicked.connect (() => {
            PixelSaver.TitleBarManager.INSTANCE.minimize_active_window();
        });

        this.maximize_button.clicked.connect (() => {
            PixelSaver.TitleBarManager.INSTANCE.toggle_maximize_active_window();
        });

        this.close_button.clicked.connect (() => {
            PixelSaver.TitleBarManager.INSTANCE.close_active_window();
        });

        PixelSaver.TitleBarManager.INSTANCE.on_title_changed.connect((title) => {
            this.label.set_text(title);
            this.label.set_tooltip_text(title);
        });

        PixelSaver.TitleBarManager.INSTANCE.on_window_state_changed.connect((is_maximized) => {
            if(is_maximized) {
                this.maximize_button.image = this.restore_image;
            } else {
                this.maximize_button.image = this.maximize_image;
            }
        });

        PixelSaver.TitleBarManager.INSTANCE.on_active_window_changed.connect((is_null) => {
            this.maximize_button.set_sensitive(!is_null);
            this.minimize_button.set_sensitive(!is_null);
            this.close_button.set_sensitive(!is_null);
        });

        settings_schema = "net.milgar.budgie-pixel-saver";
        settings_prefix = "/com/solus-project/budgie-panel/instance/pixel-saver";

        this.settings = this.get_applet_settings(uuid);
        this.settings.changed.connect(on_settings_change);
        this.on_settings_change("size");

        show_all();
    }

    void on_settings_change(string key) {
        if (key == "size") {
            this.label.set_max_width_chars(settings.get_int(key));
            this.label.set_width_chars(settings.get_int(key));
        } else if (key == "visibility") {
            int visibility = settings.get_int(key);
            switch (visibility) {
                case 0:
                    this.label.show();
                    break;
                case 1:
                    this.label.show();
                    this.maximize_button.hide();
                    this.minimize_button.hide();
                    this.close_button.hide();
                    break;
                case 2:
                    this.label.hide();
                    this.maximize_button.show();
                    this.minimize_button.show();
                    this.close_button.show();
                    break;

            }
        }

        queue_resize();
    }

    public override bool supports_settings() {
        return true;
    }

    public override Gtk.Widget? get_settings_ui()
    {
        return new AppletSettings(this.get_applet_settings(uuid));
    }
}

public class AppletSettings : Gtk.Grid
{
    Settings? settings = null;

    public AppletSettings(Settings settings)
    {
        this.settings = settings;

        this.margin = 8;

        Gtk.Label label_size = new Gtk.Label("Title size");
        label_size.set_hexpand(true);
        label_size.set_halign(Gtk.Align.START);
        this.attach(label_size, 0,0,1,1);
        Gtk.SpinButton spinbutton_size = new Gtk.SpinButton.with_range (0, 100, 1);
        spinbutton_size.set_hexpand(true);
        spinbutton_size.set_halign(Gtk.Align.END);
        this.attach(spinbutton_size, 1,0,1,1);
        this.settings.bind("size", spinbutton_size, "value", SettingsBindFlags.DEFAULT);


        Gtk.ListStore list_store = new Gtk.ListStore (2, typeof (int), typeof (string));
        Gtk.TreeIter iter;

        list_store.append (out iter);
        list_store.set (iter, 0, 0, 1, "Title & Buttons");
        list_store.append (out iter);
        list_store.set (iter, 0, 1, 1, "Title");
        list_store.append (out iter);
        list_store.set (iter, 0, 2, 1, "Buttons");

        Gtk.Label label_visibility = new Gtk.Label("Visible parts");
        label_visibility.set_hexpand(true);
        label_visibility.set_halign(Gtk.Align.START);
        this.attach(label_visibility, 0,1,1,1);

        Gtk.ComboBox visibility = new Gtk.ComboBox.with_model (list_store);
        visibility.set_hexpand(true);
        visibility.set_halign(Gtk.Align.END);
        Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
        visibility.pack_start (renderer, true);
        visibility.add_attribute (renderer, "text", 1);
        this.attach(visibility, 1,1,1,1);

        this.settings.bind("visibility", visibility, "active", SettingsBindFlags.DEFAULT);
    }
}

}

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(PixelSaver.Plugin));
}

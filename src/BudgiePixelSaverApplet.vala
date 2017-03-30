
namespace PixelSaver {

const int VISIBILITY_TITLE_BUTTONS = 0;
const int VISIBILITY_TITLE = 1;
const int VISIBILITY_BUTTONS = 2;

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

    PixelSaver.TitleBarManager title_bar_manager;

    public Applet(string uuid)
    {
        Object(uuid: uuid);
        this.title_bar_manager = PixelSaver.TitleBarManager.INSTANCE;
        this.title_bar_manager.register();

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
                this.title_bar_manager.toggle_maximize_active_window();
            }
            return Gdk.EVENT_PROPAGATE;
        });

        this.minimize_button.clicked.connect (() => {
            this.title_bar_manager.minimize_active_window();
        });

        this.maximize_button.clicked.connect (() => {
            this.title_bar_manager.toggle_maximize_active_window();
        });

        this.close_button.clicked.connect (() => {
            this.title_bar_manager.close_active_window();
        });

        this.title_bar_manager.on_title_changed.connect((title) => {
            this.label.set_text(title);
            this.label.set_tooltip_text(title);
        });

        this.title_bar_manager.on_window_state_changed.connect((is_maximized) => {
            if(is_maximized) {
                this.maximize_button.image = this.restore_image;
            } else {
                this.maximize_button.image = this.maximize_image;
            }
        });

        this.title_bar_manager.on_active_window_changed.connect(
            (is_null, can_minimize, can_maximize, can_close) => {
                this.minimize_button.set_sensitive(can_minimize);
                this.maximize_button.set_sensitive(can_maximize);
                this.close_button.set_sensitive(can_close);
            }
        );

        settings_schema = "net.milgar.budgie-pixel-saver";
        settings_prefix = "/com/solus-project/budgie-panel/instance/pixel-saver";

        this.settings = this.get_applet_settings(uuid);
        this.settings.changed.connect(on_settings_change);
        show_all();
        this.on_settings_change("size");
        this.on_settings_change("visibility");

    }

    ~Applet(){
        this.title_bar_manager.unregister();
    }

    void on_settings_change(string key) {
        if (key == "size") {
            this.label.set_max_width_chars(settings.get_int(key));
            this.label.set_width_chars(settings.get_int(key));
        } else if (key == "visibility") {
            int visibility = settings.get_int(key);
            switch (visibility) {
                case VISIBILITY_TITLE_BUTTONS:
                    this.label.show();
                    this.maximize_button.show();
                    this.minimize_button.show();
                    this.close_button.show();
                    break;
                case VISIBILITY_TITLE:
                    this.label.show();
                    this.maximize_button.hide();
                    this.minimize_button.hide();
                    this.close_button.hide();
                    break;
                case VISIBILITY_BUTTONS:
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

        Gtk.Label label_size = new Gtk.Label("Title Length");
        label_size.set_hexpand(true);
        label_size.set_halign(Gtk.Align.START);
        this.attach(label_size, 0,0,1,1);
        Gtk.SpinButton spinbutton_size = new Gtk.SpinButton.with_range (0, 100, 1);
        spinbutton_size.set_hexpand(true);
        spinbutton_size.set_halign(Gtk.Align.END);
        this.attach(spinbutton_size, 1,0,1,1);
        this.settings.bind("size", spinbutton_size, "value", SettingsBindFlags.DEFAULT);

        Gtk.ListStore list_store = new Gtk.ListStore (1,typeof (string));
        list_store.insert_with_values (null, VISIBILITY_TITLE_BUTTONS, 0, "Title & Buttons");
        list_store.insert_with_values (null, VISIBILITY_TITLE, 0, "Title");
        list_store.insert_with_values (null, VISIBILITY_BUTTONS, 0, "Buttons");

        Gtk.Label label_visibility = new Gtk.Label("Visibility");
        label_visibility.set_hexpand(true);
        label_visibility.set_halign(Gtk.Align.START);
        this.attach(label_visibility, 0,1,1,1);

        Gtk.ComboBox visibility = new Gtk.ComboBox.with_model (list_store);
        visibility.set_hexpand(true);
        visibility.set_halign(Gtk.Align.END);
        Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
        visibility.pack_start (renderer, true);
        visibility.add_attribute (renderer, "text", 0);
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

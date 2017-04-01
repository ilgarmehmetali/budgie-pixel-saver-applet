
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

    bool is_buttons_visible {get; set;}
    bool is_title_visible {get; set;}
    bool is_active_window_csd {get; set;}
    bool is_active_window_maximized {get; set;}

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

        event_box.button_release_event.connect ((event) => {
            if (event.button == 3) {
                Wnck.ActionMenu menu = this.title_bar_manager.get_action_menu_for_active_window();
                menu.popup(null, null, null, event.button, Gtk.get_current_event_time());
                return true;
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
            this.is_active_window_maximized = is_maximized;
            this.update_visibility(false);
            if(is_maximized) {
                this.maximize_button.image = this.restore_image;
            } else {
                this.maximize_button.image = this.maximize_image;
            }
        });

        this.title_bar_manager.on_active_window_changed.connect(
            (can_minimize, can_maximize, can_close, is_active_window_csd, is_active_window_maximized) => {
                this.minimize_button.set_sensitive(can_minimize);
                this.maximize_button.set_sensitive(can_maximize);
                this.close_button.set_sensitive(can_close);
                this.is_active_window_csd = is_active_window_csd;
                this.is_active_window_maximized = is_active_window_maximized;
                this.update_visibility(false);
            }
        );

        settings_schema = "net.milgar.budgie-pixel-saver";
        settings_prefix = "/net/milgar/budgie-pixel-saver";

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
                    this.is_buttons_visible = true;
                    this.is_title_visible = true;
                    break;
                case VISIBILITY_TITLE:
                    this.is_buttons_visible = false;
                    this.is_title_visible = true;
                    break;
                case VISIBILITY_BUTTONS:
                    this.is_buttons_visible = true;
                    this.is_title_visible = false;
                    break;
            }
        }
        this.update_visibility(true);
    }

    void update_visibility(bool is_settings_changed = false){
        bool hide_for_csd = this.is_active_window_csd && this.settings.get_boolean("hide-for-csd");
        bool hide_for_unmaximized = !this.is_active_window_maximized && this.settings.get_boolean("hide-for-unmaximized");

        if( !this.is_buttons_visible || hide_for_unmaximized || hide_for_csd ) {
            this.maximize_button.hide();
            this.minimize_button.hide();
            this.close_button.hide();
        } else {
            this.maximize_button.show();
            this.minimize_button.show();
            this.close_button.show();
        }

        if(!this.is_title_visible || hide_for_csd || hide_for_unmaximized) {
            this.label.hide();
        } else {
            this.label.show();
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

[GtkTemplate (ui = "/net/milgar/budgie-pixel-saver/settings.ui")]
public class AppletSettings : Gtk.Grid
{
    Settings? settings = null;

    [GtkChild]
    private Gtk.SpinButton? spinbutton_length;

    [GtkChild]
    private Gtk.ComboBox? combobox_visibility;

    [GtkChild]
    private Gtk.Switch? switch_csd;

    [GtkChild]
    private Gtk.Switch? switch_unmaximized;

    public AppletSettings(Settings? settings)
    {
        this.settings = settings;

        this.settings.bind("size", spinbutton_length, "value", SettingsBindFlags.DEFAULT);
        this.settings.bind("visibility", combobox_visibility, "active", SettingsBindFlags.DEFAULT);
        this.settings.bind("hide-for-csd", switch_csd, "active", SettingsBindFlags.DEFAULT);
        this.settings.bind("hide-for-unmaximized", switch_unmaximized, "active", SettingsBindFlags.DEFAULT);
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

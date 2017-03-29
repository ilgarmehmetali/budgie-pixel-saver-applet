
public class BudgiePixelSaverPlugin : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new BudgiePixelSaverApplet();
    }
}

public class BudgiePixelSaverApplet : Budgie.Applet
{
    Gtk.Label label;
    static int MAX_TITLE_LENGHT = 40;
    Gtk.Button minimize_button;
    Gtk.Button maximize_button;
    Gtk.Button close_button;
    Gtk.Image maximize_image;
    Gtk.Image restore_image;


    public BudgiePixelSaverApplet()
    {

        this.minimize_button = new Gtk.Button.from_icon_name ("window-minimize-symbolic");
        this.maximize_button = new Gtk.Button.from_icon_name ("window-maximize-symbolic");
        this.close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.BUTTON);

        this.maximize_image = new Gtk.Image.from_icon_name ("window-maximize-symbolic", Gtk.IconSize.BUTTON);
        this.restore_image = new Gtk.Image.from_icon_name ("window-restore-symbolic", Gtk.IconSize.BUTTON);


        this.label = new Gtk.Label ("");
        this.label.set_ellipsize (Pango.EllipsizeMode.END);
        this.label.set_max_width_chars(MAX_TITLE_LENGHT);
        this.label.set_width_chars(MAX_TITLE_LENGHT);
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
                BPS.TitleBarManager.INSTANCE.toggle_maximize_active_window();
            }
            return Gdk.EVENT_PROPAGATE;
        });

        this.minimize_button.clicked.connect (() => {
            BPS.TitleBarManager.INSTANCE.minimize_active_window();
        });

        this.maximize_button.clicked.connect (() => {
            BPS.TitleBarManager.INSTANCE.toggle_maximize_active_window();
        });

        this.close_button.clicked.connect (() => {
            BPS.TitleBarManager.INSTANCE.close_active_window();
        });

        BPS.TitleBarManager.INSTANCE.on_title_changed.connect((title) => {
            debug("title changed: %s", title);
            this.label.set_text(title);
            this.label.set_tooltip_text(title);
        });

        BPS.TitleBarManager.INSTANCE.on_window_state_changed.connect((is_maximized) => {
            if(is_maximized) {
                this.maximize_button.image = this.restore_image;
            } else {
                this.maximize_button.image = this.maximize_image;
            }
        });

        BPS.TitleBarManager.INSTANCE.on_active_window_changed.connect((is_null) => {
            this.maximize_button.set_sensitive(!is_null);
            this.minimize_button.set_sensitive(!is_null);
            this.close_button.set_sensitive(!is_null);
        });

        show_all();
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(BudgiePixelSaverPlugin));
}


public class BudgiePixelSaverPlugin : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new BudgiePixelSaverApplet();
    }
}

public class BudgiePixelSaverApplet : Budgie.Applet
{

    Wnck.Screen screen;
    Wnck.Window active_window;
    Gtk.Label label;
    static int MAX_TITLE_LENGHT = 40;
    Gtk.Button minimize_button;
    Gtk.Button maximize_button;
    Gtk.Button close_button;
    Gtk.Image maximize_image;
    Gtk.Image restore_image;


    public BudgiePixelSaverApplet()
    {

        this.screen = Wnck.Screen.get_default();
        this.active_window = this.screen.get_active_window();


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
            if (event.type == Gdk.EventType.@2BUTTON_PRESS && this.active_window != null){
                if (this.active_window.is_maximized())
                    this.active_window.unmaximize();
                else
                    this.active_window.maximize();
            }
            return Gdk.EVENT_PROPAGATE;
        });

        this.minimize_button.clicked.connect (() => {
            this.active_window.minimize();
        });

        this.maximize_button.clicked.connect (() => {
            if(this.active_window.is_maximized())
                this.active_window.unmaximize();
            else
                this.active_window.maximize();
        });

        this.close_button.clicked.connect (() => {
            this.active_window.close(this.get_x_server_time());
        });

        this.screen.active_window_changed.connect( this.on_active_window_changed );
        this.screen.window_opened.connect( this.on_window_opened );
        this.screen.force_update();
        unowned List<Wnck.Window> windows = this.screen.get_windows_stacked();
        foreach(Wnck.Window window in windows){
            if(window.get_window_type() != Wnck.WindowType.NORMAL) continue;

            this.toggle_title_bar_for_window(window, false);
        }
        this.on_active_window_changed(this.screen.get_active_window());
        show_all();

        this.screen.window_closed.connect( (w) => {
            this.screen.force_update();
            this.on_active_window_changed(w);
        });
    }

    ~BudgiePixelSaverApplet() {
        unowned List<Wnck.Window> windows = this.screen.get_windows_stacked();
        foreach(Wnck.Window window in windows){
            if(window.get_window_type() != Wnck.WindowType.NORMAL) continue;

            this.toggle_title_bar_for_window(window, true);
        }
    }

    private void toggle_title_bar_for_window(Wnck.Window window, bool is_on){
        try {
            string[] spawn_args = {"xprop", "-id", "%#.8x".printf((uint)window.get_xid()),
                "-f", "_GTK_HIDE_TITLEBAR_WHEN_MAXIMIZED", "32c", "-set",
                "_GTK_HIDE_TITLEBAR_WHEN_MAXIMIZED", is_on ? "0x0" : "0x1"};
            string[] spawn_env = Environ.get ();
            Pid child_pid;

            Process.spawn_async ("/",
                spawn_args,
                spawn_env,
                SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                null,
                out child_pid);

            ChildWatch.add (child_pid, (pid, status) => {
                if(window.is_maximized()) {
                    window.unmaximize();
                    window.maximize();
                }
                Process.close_pid (pid);
            });
        } catch(SpawnError e){
            error(e.message);
        }
    }

    private void on_active_window_changed(Wnck.Window previous_window){
        if(previous_window != null){
            previous_window.name_changed.disconnect( this.on_active_window_name_changed );
            previous_window.state_changed.disconnect( this.on_active_window_state_changed );
        }

        this.active_window = this.screen.get_active_window();
        if(this.active_window.get_window_type() != Wnck.WindowType.NORMAL){
            this.active_window = null;
        }

        if(this.active_window != null){
            this.active_window.name_changed.connect( this.on_active_window_name_changed );
            this.active_window.state_changed.connect( this.on_active_window_state_changed );
            this.set_states(true, this.active_window.get_name());
            this.set_maximize_restore_icon();
        } else {
            this.set_states(false, "");
        }
    }

    private void on_window_opened(Wnck.Window window){
        this.toggle_title_bar_for_window(window, false);
    }

    private void set_states(bool is_enabled, string title){
        this.maximize_button.set_sensitive(is_enabled);
        this.minimize_button.set_sensitive(is_enabled);
        this.close_button.set_sensitive(is_enabled);
        this.set_title(title);
    }

    private void on_active_window_name_changed(){
        this.set_title(this.active_window.get_name());
    }

    private void on_active_window_state_changed(Wnck.WindowState changed_mask, Wnck.WindowState new_state){
        this.set_maximize_restore_icon();
    }

    private void set_maximize_restore_icon(){
        if(this.active_window.is_maximized()) {
            this.maximize_button.image = this.restore_image;
        } else {
            this.maximize_button.image = this.maximize_image;
        }
    }

    private void set_title(string name){
        this.label.set_text(name);
        this.label.set_tooltip_text(name);
    }

    private uint32 get_x_server_time() {
        unowned X.Window xwindow = Gdk.X11.get_default_root_xwindow();
        unowned X.Display xdisplay = Gdk.X11.get_default_xdisplay();
        Gdk.X11.Display display = Gdk.X11.Display.lookup_for_xdisplay(xdisplay);
        Gdk.X11.Window window = new Gdk.X11.Window.foreign_for_display(display, xwindow);
        return Gdk.X11.get_server_time(window);
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(BudgiePixelSaverPlugin));
}

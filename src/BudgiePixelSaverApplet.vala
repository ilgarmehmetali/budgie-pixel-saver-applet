/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2015-2016 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

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
    Wnck.Window activeWindow;
    Gtk.Label label;
    static int MAX_TITLE_LENGHT = 40;
    Gtk.Button minimizeButton;
    Gtk.Button maximizeButton;
    Gtk.Button closeButton;
    Gtk.Image maximizeImage;
    Gtk.Image restoreImage;


    public BudgiePixelSaverApplet()
    {

        this.screen = Wnck.Screen.get_default();
        this.activeWindow = this.screen.get_active_window();


        this.minimizeButton = new Gtk.Button.from_icon_name ("window-minimize-symbolic");
        this.maximizeButton = new Gtk.Button.from_icon_name ("window-maximize-symbolic");
        this.closeButton = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.BUTTON);

		this.maximizeImage = new Gtk.Image.from_icon_name ("window-restore-symbolic", Gtk.IconSize.BUTTON);
        this.restoreImage = new Gtk.Image.from_icon_name ("window-maximize-symbolic", Gtk.IconSize.BUTTON);


		this.label = new Gtk.Label ("");
		this.label.set_ellipsize (Pango.EllipsizeMode.END);
        this.label.set_max_width_chars(MAX_TITLE_LENGHT);
        this.label.set_width_chars(MAX_TITLE_LENGHT);
        this.label.set_alignment(0, 0.5f);

        Gtk.Box box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.pack_start (this.label, true, false, 0);
        box.pack_start (this.minimizeButton, false, false, 0);
        box.pack_start (this.maximizeButton, false, false, 0);
        box.pack_start (this.closeButton, false, false, 0);
        this.add (box);

        this.minimizeButton.clicked.connect (() => {
            this.activeWindow.minimize();
        });

        this.maximizeButton.clicked.connect (() => {
            if(this.activeWindow.is_maximized())
                this.activeWindow.unmaximize();
            else
                this.activeWindow.maximize();
        });

        this.closeButton.clicked.connect (() => {
            unowned X.Window xwindow = Gdk.X11.get_default_root_xwindow();
            unowned X.Display xdisplay = Gdk.X11.get_default_xdisplay();
            Gdk.X11.Display display = Gdk.X11.Display.lookup_for_xdisplay(xdisplay);
            Gdk.X11.Window window = new Gdk.X11.Window.foreign_for_display(display, xwindow);
            this.activeWindow.close(Gdk.X11.get_server_time(window));
        });

        screen.active_window_changed.connect( this.onActiveWindowChanged );
        show_all();

    }

    private void onActiveWindowChanged(Wnck.Window previousWindow){
        //check if its null
        if(previousWindow != null){
            previousWindow.name_changed.disconnect( this.onActiveWindowNameChanged );
            previousWindow.state_changed.disconnect( this.onActiveWindowStateChanged );
        }

        this.activeWindow = this.screen.get_active_window();
        if(this.activeWindow != null){
            this.activeWindow.name_changed.connect( this.onActiveWindowNameChanged );
            this.activeWindow.state_changed.connect( this.onActiveWindowStateChanged );
            this.setTitle(this.activeWindow.get_name());
            this.maximizeButton.set_sensitive(true);
            this.minimizeButton.set_sensitive(true);
            this.closeButton.set_sensitive(true);
        } else {
            this.maximizeButton.set_sensitive(false);
            this.minimizeButton.set_sensitive(false);
            this.closeButton.set_sensitive(false);
        }
    }

    private void onActiveWindowNameChanged(){
        this.setTitle(this.activeWindow.get_name());
    }

    private void onActiveWindowStateChanged(Wnck.WindowState changed_mask, Wnck.WindowState new_state){
        if(this.activeWindow.is_maximized()) {
			this.maximizeButton.image = this.restoreImage;
        } else {
			this.maximizeButton.image = this.maximizeImage;
        }
    }

    private void setTitle(string name){
        this.label.set_text(name);
        this.label.set_tooltip_text(name);
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(BudgiePixelSaverPlugin));
}

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */

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

        this.maximizeImage = new Gtk.Image.from_icon_name ("window-maximize-symbolic", Gtk.IconSize.BUTTON);
        this.restoreImage = new Gtk.Image.from_icon_name ("window-restore-symbolic", Gtk.IconSize.BUTTON);


        this.label = new Gtk.Label ("");
        this.label.set_ellipsize (Pango.EllipsizeMode.END);
        this.label.set_max_width_chars(MAX_TITLE_LENGHT);
        this.label.set_width_chars(MAX_TITLE_LENGHT);
        this.label.set_alignment(0, 0.5f);

        Gtk.Box box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.pack_start (this.label, false, false, 0);
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
        screen.window_opened.connect( this.onWindowOpened );
        this.screen.force_update();
        unowned GLib.List<Wnck.Window> windows = this.screen.get_windows();
        foreach(Wnck.Window window in windows){
            if(window.get_window_type() != Wnck.WindowType.NORMAL) continue;

            this.hideTitleBarForWindow(window);
        }
        show_all();

    }

    private void hideTitleBarForWindow(Wnck.Window window){
        string cmd = "xprop -id %#.8x -f _GTK_HIDE_TITLEBAR_WHEN_MAXIMIZED 32c -set _GTK_HIDE_TITLEBAR_WHEN_MAXIMIZED 0x1";

        try {
            GLib.Process.spawn_command_line_async(cmd.printf((uint) window.get_xid()));
            if(window.is_maximized()) {
                window.unmaximize();
                window.maximize();
            }
        } catch(SpawnError e){
            GLib.error(e.message);
        }
    }

    private void onActiveWindowChanged(Wnck.Window previousWindow){
        if(previousWindow != null){
            previousWindow.name_changed.disconnect( this.onActiveWindowNameChanged );
            previousWindow.state_changed.disconnect( this.onActiveWindowStateChanged );
        }

        this.activeWindow = this.screen.get_active_window();
        if(this.activeWindow.get_window_type() != Wnck.WindowType.NORMAL){
            this.activeWindow = null;
        }

        if(this.activeWindow != null){
            this.activeWindow.name_changed.connect( this.onActiveWindowNameChanged );
            this.activeWindow.state_changed.connect( this.onActiveWindowStateChanged );
            this.setStates(true, this.activeWindow.get_name());
            this.setMaximizeRestoreIcon();
        } else {
            this.setStates(false, "");
        }
    }

    private void onWindowOpened(Wnck.Window window){
        this.hideTitleBarForWindow(window);
    }

    private void setStates(bool isEnabled, string title){
        this.maximizeButton.set_sensitive(isEnabled);
        this.minimizeButton.set_sensitive(isEnabled);
        this.closeButton.set_sensitive(isEnabled);
        this.setTitle(title);
    }

    private void onActiveWindowNameChanged(){
        this.setTitle(this.activeWindow.get_name());
    }

    private void onActiveWindowStateChanged(Wnck.WindowState changed_mask, Wnck.WindowState new_state){
        this.setMaximizeRestoreIcon();
    }

    private void setMaximizeRestoreIcon(){
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

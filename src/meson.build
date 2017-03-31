
custom_target('plugin-file-workspaces',
    input : 'BudgiePixelSaverApplet.plugin.in',
    output : 'BudgiePixelSaverApplet.plugin',
    command : ['cp', '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir: LIB_INSTALL_DIR,
)

gresource = join_paths(meson.current_source_dir(), 'plugin.gresource.xml')

# Compile the assets into the binary
applet_budgie_pixel_saver_resources = gnome.compile_resources(
    'budgie-pixel-saver-applet-resources',
    gresource,
    source_dir: meson.current_source_dir(),
    c_name: 'budgie_pixel_saver',
)


applet_budgie_pixel_saver_sources = [
    'BudgiePixelSaverApplet.vala',
    'TitleBarManager.vala',
    applet_budgie_pixel_saver_resources,
]

applet_budgie_pixel_saver_deps = [
    dep_gtk3,
    dep_glib,
    dep_wnck,
    dep_peas,
    dep_budgie,
    dep_gdkx11,
]

shared_library(
    'budgiepixelsaverapplet',
    applet_budgie_pixel_saver_sources,
    dependencies: applet_budgie_pixel_saver_deps,
    vala_args: [
    ],
    c_args: [
        '-DWNCK_I_KNOW_THIS_IS_UNSTABLE',
    ],
    install: true,
    install_dir: LIB_INSTALL_DIR,
)

install_data('net.milgar.budgie-pixel-saver.gschema.xml',
    install_dir: '/usr/share/glib-2.0/schemas'
)

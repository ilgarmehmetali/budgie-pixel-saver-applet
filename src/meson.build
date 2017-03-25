
custom_target('plugin-file-workspaces',
    input : 'BudgiePixelSaverApplet.plugin.in',
    output : 'BudgiePixelSaverApplet.plugin',
    command : ['cp', '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir : meson.current_build_dir() + '/src')


applet_budgie_pixel_saver_sources = [
    'BudgiePixelSaverApplet.vala',
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
    install: false,
)

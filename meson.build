project(
    'budgie_pixel_saver_applet',
    ['c', 'vala'],
    version: '10.2.9',
    license: [
        'GPL-2.0',
        'LGPL-2.1',
    ],
    default_options: [
        'c_std=c11',
    ],
)



am_cflags = [
    '-fstack-protector',
    '-pedantic',
    '-Wstrict-prototypes',
    '-Wundef',
    '-Werror-implicit-function-declaration',
    '-Wformat',
    '-Wformat-security',
    '-Werror=format-security',
    '-Wconversion',
    '-Wunused-variable',
    '-Wunreachable-code',
    '-Wall',
    '-W',
]

add_global_arguments(am_cflags, language: 'c')

dep_gtk3 = dependency('gtk+-3.0', version: '>=3.18')
dep_gdkx11 = dependency('gdk-x11-3.0', version: '>=3.18')
dep_glib = dependency('glib-2.0', version: '>= 2.46.0')
dep_peas = dependency('libpeas-1.0', version: '>= 1.8.0')
dep_budgie = dependency('budgie-1.0', version: '>= 2')
dep_wnck = dependency('libwnck-3.0', version: '>= 3.14.0')

meson.add_install_script('./install.sh')

subdir('src')

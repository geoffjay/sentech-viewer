project('sentech-viewer', 'vala', 'c',
        license: 'GPL3+',
        version: '0.1.0'
)

version_split = meson.project_version().split('.')
MAJOR_VERSION = version_split[0]
MINOR_VERSION = version_split[1]
MICRO_VERSION = version_split[2]

pkglibdir_abs = join_paths(get_option('prefix'), get_option('libdir'), 'sentech-viewer')
pkglibdir = join_paths(get_option('libdir'), 'sentech-viewer')

status = [
  '', '',
  'sentech-viewer @0@'.format(meson.project_version()),
  '', '',
  'Version ............... : @0@'.format(meson.project_version()),
  'Build Type ............ : @0@'.format(get_option('buildtype')),
  '',
  'Prefix ................ : @0@'.format(get_option('prefix')),
  'Libdir ................ : @0@'.format(join_paths(get_option('prefix'), get_option('libdir'))),
  '',
]

add_project_arguments(['--target-glib', '2.38'], language: 'vala')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

gio_dep = dependency('gio-2.0', version: '>= 2.48')
gtk_dep = dependency('gtk+-3.0', version: '>= 3.20')
arv_dep = dependency('aravis-0.6', version: '>= 0.5')
clutter_dep = dependency('clutter-gtk-1.0', version: '>= 1.8')
cogl_dep = dependency('cogl-1.0', version: '>= 1.22')
posix_dep = meson.get_compiler('vala').find_library('posix')

uvc_vapi = meson.get_compiler('vala').find_library('uvc', dirs: join_paths(meson.current_source_dir(), 'vapi'))
uvc_dep = declare_dependency(dependencies: [uvc_vapi])

gnome = import('gnome')
i18n = import('i18n')

subdir('src')

meson.add_install_script('build-aux/meson/meson_post_install.py')

# 'dist' will be used by meson, avoid conflicting
run_target('builder-dist',
  command: [
    find_program('build-aux/meson/meson_dist.sh'),
    meson.project_version(),
    meson.project_name(),
  ]
)

message('\n  '.join(status))

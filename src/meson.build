sentech_viewer_resources = gnome.compile_resources('sentech-resources',
  'sentech.gresource.xml',
  c_name: 'sentech',
)

sentech_viewer_sources = [
  'main.vala',
  'window.vala',
  'controls/gc-boolean-edit.vala',
  'controls/gc-enum-edit.vala',
  'controls/gc-float-edit.vala',
  'controls/gc-string-edit.vala',
  'controls/gc-integer-edit.vala',
  'colorspaces.c',
  'colorspaces.h',
  'defs.h',
]

sentech_deps = [
  gio_dep,
  gtk_dep,
  arv_dep,
  clutter_dep,
  cogl_dep,
  posix_dep,
  uvc_dep,
]

exe_link_args = [ '-pie' ]
exe_c_args = [ '-fPIE' ]

executable('sentech-viewer', sentech_viewer_resources + sentech_viewer_sources,
        gui_app: true,
        install: true,
         c_args: exe_c_args,
      link_args: exe_link_args,
  install_rpath: pkglibdir_abs,
   dependencies: sentech_deps,
)

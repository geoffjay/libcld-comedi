libcld_comedi_header_subdir = 'cld-' + apiversion
libcld_comedi_header_dir = join_paths(includedir, libcld_comedi_header_subdir)

version_data = configuration_data()
version_data.set('CLD_MAJOR_VERSION', cld_version_major)
version_data.set('CLD_MINOR_VERSION', cld_version_minor)
version_data.set('CLD_MICRO_VERSION', cld_version_micro)
version_data.set('CLD_VERSION', meson.project_version())
version_data.set10('ENABLE_TRACING', get_option('enable_tracing'))

cld_comedi_version_h = configure_file(
          input: 'cld-comedi-version.h.in',
         output: 'cld-comedi-version.h',
    install_dir: libcld_comedi_header_dir,
        install: true,
  configuration: version_data)

cld_comedi_debug_h = configure_file(
          input: 'cld-comedi-debug.h.in',
         output: 'cld-comedi-debug.h',
    install_dir: libcld_comedi_header_dir,
        install: true,
  configuration: version_data)

libcld_comedi_generated_headers = [
  cld_comedi_debug_h,
  cld_comedi_version_h,
]

libcld_comedi_deps = [
  libgio_dep,
  libgee_dep,
  libxml_dep,
  libjson_glib_dep,
  libcomedi_dep,
  linux_dep,
  posix_dep,
  cc.find_library('m', required: false),
]

libcld_comedi_sources = [
  libcld_comedi_generated_headers,
  'cld-comedi.vala',
  'cld-comedi-device.vala',
  'cld-comedi-factory.vala',
  'cld-comedi-task.vala',
]

if libdir == '' or includedir == ''
  error('You must set pkglibdir and pkgincludedir when using as a subproject')
endif

libcld_comedi = library('cld-' + apiversion, libcld_comedi_sources,
  link_depends: 'cld.map',
     link_args: [ '-Wl,--version-script,' + join_paths(meson.current_source_dir(), 'cld.map'), '-lcomedi' ],
   vala_header: 'cld.h',
     vala_vapi: 'cld-@0@.vapi'.format(apiversion),
      vala_gir: 'Cld-@0@.gir'.format(apiversion),
  dependencies: libcld_deps,
     soversion: soversion,
       version: libversion,
       install: true,
   install_dir: [ true, true, true, true ],
)

g_ir_compiler = find_program('g-ir-compiler', required: false)
if g_ir_compiler.found()
  custom_target('CldComedi typelib',
        command: [ g_ir_compiler, '--shared-library', libcld_comedi.full_path(), '--output', '@OUTPUT@', join_paths(meson.current_build_dir(), 'Cld-@0@.gir'.format(apiversion)) ],
         output: 'Cld-@0@.typelib'.format(apiversion),
        depends: libcld_comedi,
        install: true,
    install_dir: join_paths(get_option('libdir'), 'girepository-1.0')
)
endif

libcld_comedi_dep = declare_dependency(
              sources: libcld_comedi_generated_headers,
         dependencies: libcld_comedi_deps,
            link_with: libcld_comedi,
  include_directories: include_directories('.'),
)

pkgg = import('pkgconfig')

pkgg.generate(
    libraries: [libcld_comedi],
      subdirs: join_paths(package_subdir, libcld_comedi_header_subdir),
      version: meson.project_version(),
         name: 'cld',
     filebase: 'cld-@0@'.format(apiversion),
  description: 'A DAQ object library for GLib',
     requires: 'gio-2.0',
  install_dir: join_paths(libdir, 'pkgconfig'),
)

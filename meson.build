project('cld-comedi', 'vala', 'c',
          version: '0.4.8',
          license: 'LGPLv2.1+',
    meson_version: '>= 0.38.1',
  default_options: [ 'warning_level=1', 'buildtype=debugoptimized' ],
)

version_arr = meson.project_version().split('.')
cld_version_major = version_arr[0].to_int()
cld_version_minor = version_arr[1].to_int()
cld_version_micro = version_arr[2].to_int()

apiversion = '1.0'
soversion = 0

if cld_version_minor.is_odd()
  cld_interface_age = 0
else
  cld_interface_age = cld_version_micro
endif

current = cld_version_minor * 100 + cld_version_micro - cld_interface_age
revision = cld_interface_age
libversion = '@0@.@1@.@2@'.format(soversion, current, revision)

config_h = configuration_data()
config_h.set_quoted('GETTEXT_PACKAGE', 'libcld-comedi')
config_h.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))

configure_file(
  output: 'config.h',
  configuration: config_h,
)

add_project_arguments([
  '--thread',
  ['--target-glib', '2.44'],
  ['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
], language: 'vala')

libcld_dep = dependency('cld-1.0')

libgio_dep = dependency('gio-2.0')
libgee_dep = dependency('gee-0.8')
libxml_dep = dependency('libxml-2.0')
libjson_glib_dep = dependency('json-glib-1.0')

linux_dep = meson.get_compiler('vala').find_library('linux')
posix_dep = meson.get_compiler('vala').find_library('posix')

libcomedi_vapi = meson.get_compiler('vala').find_library('comedi', dirs: join_paths(meson.current_source_dir(), 'vapi'))
libcomedi_dep = declare_dependency(dependencies: [libcomedi_vapi])

add_project_arguments([
  '-DHAVE_CONFIG_H',
  '-I' + meson.build_root(),
  '-I' + join_paths(meson.source_root(), 'src'),
  '-DCLD_COMPILATION',
], language: 'c')

cc = meson.get_compiler('c')

global_c_args = []
test_c_args = [
  '-Wcast-align',
  '-Wdeclaration-after-statement',
  ['-Werror=format-security', '-Werror=format=2'],
  '-Wformat-nonliteral',
  '-Wformat-security',
  '-Wmissing-include-dirs',
  '-Wnested-externs',
  '-Wno-missing-field-initializers',
  '-Wno-sign-compare',
  '-Wno-strict-aliasing',
  '-Wno-uninitialized',
  '-Wno-unused-parameter',
  '-Wpointer-arith',
  '-Wredundant-decls',
  '-Wshadow',
  '-Wswitch-default',
  '-Wswitch-enum',
  '-Wundef',
]
if get_option('buildtype') != 'plain'
  test_c_args += '-fstack-protector-strong'
endif
if get_option('enable_profiling')
  test_c_args += '-pg'
endif

foreach arg: test_c_args
  if cc.has_multi_arguments(arg)
    global_c_args += arg
  endif
endforeach
add_project_arguments(
  global_c_args,
  language: 'c'
)

# Setup various paths that subdirectory meson.build files need
package_subdir = get_option('package_subdir')
libdir = join_paths(get_option('libdir'), package_subdir)
includedir = join_paths(get_option('includedir'), package_subdir)
girdir = join_paths(get_option('datadir'), package_subdir, 'gir-1.0')
typelibdir = join_paths(get_option('libdir'), package_subdir, 'girepository-1.0')
if package_subdir == ''
  vapidir = join_paths(get_option('datadir'), 'vala', 'vapi')
else
  vapidir = join_paths(get_option('datadir'), package_subdir, 'vapi')
endif

gnome = import('gnome')
i18n = import('i18n')

subdir('src')
subdir('tests')

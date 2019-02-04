test_deps = [
  libcld_dep,
  libcld_comedi_dep,
  libgio_dep,
  libgee_dep,
]

legacy_test_sources = [
  'tests.vala',
  'test-comedi-device.vala',
]

test('legacy', executable('legacy-test', legacy_test_sources,
                          dependencies: test_deps))

# TODO figure out why this causes CI to fail
#python = find_program('python3')
#if g_ir_compiler.found()
    #test('gi', python,
         #args: meson.current_source_dir() + '/gi-test.py' ,
         #env: ['GI_TYPELIB_PATH=' + join_paths(meson.current_build_dir(), '../src')])
#endif

# TODO move to a new multi-exec test framework
#cld_tests = [
  #'build',
  #'configure',
  #'control',
  #'context',
#]

#foreach name : cld_tests
  #test(name, executable('test-' + name, 'test-' + name + '.vala',
                        #dependencies: test_deps),
       #env: ['G_TEST_SRCDIR=' + meson.current_source_dir()])
#endforeach

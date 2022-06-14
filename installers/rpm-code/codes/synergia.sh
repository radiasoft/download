#!/bin/bash

synergia_python_install() {
    cd synergia2
    perl -pi -e "s{(?<=find_package.Python3)}{ $RADIA_RUN_VERSION_PYTHON EXACT REQUIRED}" CMakeLists.txt
    codes_cmake \
        -D BOOST_ROOT="${codes_dir[prefix]}" \
        -D CHEF_DIR="${codes_dir[pyenv_prefix]}/lib/chef/cmake" \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[pyenv_prefix]}" \
        -D FFTW3_LIBRARY_DIRS=/usr/lib64/mpich/lib \
        -D USE_PYTHON_3=1 \
        -D USE_SIMPLE_TIMER=0
    codes_make_install
    # synergia has this in multiple CMakeLists.txt
    #   install(FILES
    #    __init__.py
    #    "${CMAKE_CURRENT_BINARY_DIR}/version.py"
    #    DESTINATION lib/synergia)
    # easier to just move it to the right place at the end.
    mv "${codes_dir[pyenv_prefix]}/lib/synergia" "$(codes_python_lib_dir)"
    cd ..
    cp src/synergia/bunch/tests/test_bunch.py ..
    cd ..
    perl -pi - test_bunch.py <<'EOF'
/sys.path.append/ && ($_ = '');
s{(?<=from )(?=foundation|bunch|utils)}{synergia.};
s{(?=import convertors)}{from synergia };
EOF
    nosetests test_bunch.py
}

synergia_main() {
    codes_dependencies fnal_chef
    codes_download https://bitbucket.org/fnalacceleratormodeling/synergia2.git mac-native
}

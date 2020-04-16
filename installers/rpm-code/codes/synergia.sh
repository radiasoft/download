#!/bin/bash

synergia_python_install() {
    cd synergia2
    # EXTRA_CXX_FLAGS, because synergia won't compile without them
    CHEF_INSTALL_DIR="${codes_dir[pyenv_prefix]}" \
        codes_cmake \
        -DBOOST_ROOT="${codes_dir[prefix]}" \
        -DBUILD_PYTHON_BINDINGS=1 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX:PATH="${codes_dir[pyenv_prefix]}" \
        -DEXTRA_CXX_FLAGS='-Wno-deprecated-declarations -Wno-sign-compare -Wno-maybe-uninitialized' \
        -DFFTW3_LIBRARY_DIRS=/usr/lib64/mpich/lib \
        -DUSE_PYTHON_3=1 \
        -DUSE_SIMPLE_TIMER=0 \
        ..
    codes_make_install
    local l="$(codes_python_lib_dir)"
    mv "${codes_dir[pyenv_prefix]}"/lib/{synergia,synergia_tools,synergia_workflow} "$l"
    echo '#' > "$l"/synergia_tools/__init__.py
}

synergia_main() {
    codes_dependencies fnal_chef
    codes_download https://bitbucket.org/fnalacceleratormodeling/synergia2.git mac-native
}

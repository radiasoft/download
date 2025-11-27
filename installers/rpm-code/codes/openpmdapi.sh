#!/bin/bash

openpmdapi_main() {
    codes_dependencies common
    # POSIT: Version that impactx and warpx want
    codes_download https://github.com/openPMD/openPMD-api/archive/refs/tags/0.16.1.tar.gz openPMD-api-0.16.1 openpmdapi 0.16.1
    codes_cmake_fix_lib_dir
    CXXFLAGS=-Wno-template-body \
         codes_cmake2  \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"  \
        -DopenPMD_INSTALL_PYTHONDIR="$(codes_python_lib_dir)" \
        -DopenPMD_USE_MPI=ON \
        -DopenPMD_USE_PYTHON=ON
    codes_cmake_build install
}

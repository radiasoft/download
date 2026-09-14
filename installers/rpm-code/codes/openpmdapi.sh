#!/bin/bash

openpmdapi_main() {
    # POSIT: Version that impactx and warpx want
    : ${openpmdapi_version:=0.16.1}
    codes_dependencies common
    codes_download "https://github.com/openPMD/openPMD-api/archive/refs/tags/$openpmdapi_version.tar.gz" \
        "openPMD-api-$openpmdapi_version" openpmdapi "$openpmdapi_version"
    CXXFLAGS=-Wno-template-body \
         codes_cmake2  \
        -DopenPMD_INSTALL_PYTHONDIR="$(codes_python_lib_dir)" \
        -DopenPMD_USE_MPI=ON \
        -DopenPMD_USE_PYTHON=ON
    codes_cmake_build install
}

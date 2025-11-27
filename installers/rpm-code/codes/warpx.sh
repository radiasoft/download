#!/bin/bash

warpx_main() {
    codes_dependencies common amrex openpmdapi pyamrex
    # POSIT: Same version as amrex and pyamrex
    codes_download https://github.com/ECP-WarpX/WarpX/archive/refs/tags/25.11.tar.gz warpx-25.11 warpx 25.11
    codes_cmake_fix_lib_dir
    CXXFLAGS=-Wno-template-body \
        codes_cmake2 \
        -D WarpX_DIMS='1;2;RZ;3' \
        -D WarpX_PYTHON=ON \
        -D WarpX_amrex_internal=OFF \
        -D WarpX_openpmd_internal=OFF \
        -D WarpX_pyamrex_internal=OFF
    codes_cmake_build install
    codes_cmake_build pip_install
}

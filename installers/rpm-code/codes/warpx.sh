#!/bin/bash

warpx_main() {
    codes_dependencies common amrex openpmdapi pyamrex
    # POSIT: Same version as amrex and pyamrex
    codes_download https://github.com/ECP-WarpX/WarpX/archive/refs/tags/24.09.tar.gz WarpX-24.09 warpx 24.09
    codes_cmake_fix_lib_dir
    codes_cmake2 \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D WarpX_DIMS='1;2;RZ;3' \
        -D WarpX_PYTHON=ON \
        -D WarpX_amrex_internal=OFF \
        -D WarpX_openpmd_internal=OFF \
        -D WarpX_pyamrex_internal=OFF
    codes_cmake_build install
    PYINSTALLOPTIONS="--jobs=$(codes_num_cores)" codes_cmake_build pip_install
}

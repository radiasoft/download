#!/bin/bash

declare _warpx_src_d

warpx_main() {
    # Uses amrex, but it seems to need to build it on its own...
    codes_dependencies common
    codes_download https://github.com/ECP-WarpX/WarpX.git
    _warpx_src_d=$PWD
    codes_cmake_fix_lib_dir
    codes_cmake2 \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D WarpX_DIMS='1;2;RZ;3' \
        -D WarpX_LIB=ON
    codes_cmake_build install
}

warpx_python_install() {
    cd "$_warpx_src_d"
    codes_cmake_build pip_install
}

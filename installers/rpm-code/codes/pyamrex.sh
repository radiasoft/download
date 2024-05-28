#!/bin/bash

pyamrex_main() {
    codes_dependencies common amrex
    codes_download https://github.com/AMReX-Codes/pyamrex/archive/refs/tags/24.04.tar.gz pyamrex-24.04 pyamrex 24.04
    codes_cmake_fix_lib_dir
    codes_cmake \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -DpyAMReX_amrex_internal=OFF
    codes_make install
}

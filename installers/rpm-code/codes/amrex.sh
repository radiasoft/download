#!/bin/bash

amrex_main() {
    codes_dependencies common
    codes_download https://github.com/AMReX-Codes/amrex/releases/download/24.04/amrex-24.04.tar.gz amrex
    codes_cmake \
        -DAMReX_BUILD_SHARED_LIBS=ON \
        -DAMReX_PIC=ON \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make install
}

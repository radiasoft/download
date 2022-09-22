#!/bin/bash

amrex_main() {
    codes_dependencies common
    codes_download https://github.com/AMReX-Codes/amrex/releases/download/22.09/amrex-22.09.tar.gz amrex
    ./configure \
        --prefix="${codes_dir[prefix]}"
    codes_make
    codes_make_install
}

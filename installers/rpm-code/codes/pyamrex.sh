#!/bin/bash

pyamrex_main() {
    codes_dependencies common amrex
    # POSIT: Same version as amrex
    codes_download https://github.com/AMReX-Codes/pyamrex/archive/refs/tags/24.09.tar.gz pyamrex-24.09 pyamrex 24.09
    codes_cmake_fix_lib_dir
    codes_cmake2 \
      -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
      -DpyAMReX_amrex_internal=OFF
    codes_cmake_build install
    codes_cmake_build pip_install
}

#!/bin/bash

pyamrex_main() {
    codes_dependencies common amrex
    codes_download https://github.com/AMReX-Codes/pyamrex/archive/refs/tags/24.05.tar.gz pyamrex-24.05 pyamrex 24.05
    codes_cmake_fix_lib_dir
    codes_cmake2 \
      -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
      -DpyAMReX_amrex_internal=OFF
    codes_cmake_build install
    codes_cmake_build pip_install
}

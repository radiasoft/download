#!/bin/bash

impactt_main() {
    codes_dependencies common
    codes_download https://github.com/impact-lbl/impact-t.git
    cd src
    codes_cmake2 -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_cmake_build install
    codes_cmake_clean
    codes_cmake2 -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" -DUSE_MPI=ON
    codes_cmake_build install
    codes_cmake_clean
}

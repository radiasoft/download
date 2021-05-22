#!/bin/bash

cgal_main() {
    codes_dependencies common
    codes_download https://github.com/CGAL/cgal/releases/download/v5.2.1/CGAL-5.2.1-library.tar.xz
    codes_cmake_fix_lib_dir
    codes_cmake -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make install
}

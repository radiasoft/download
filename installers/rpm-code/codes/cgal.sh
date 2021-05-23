#!/bin/bash

cgal_main() {
    codes_yum_dependencies gmp-devel mpfr-devel
    codes_dependencies common boost
    codes_download https://github.com/CGAL/cgal/releases/download/v5.2.1/CGAL-5.2.1-library.tar.xz CGAL-5.2.1
    codes_cmake_fix_lib_dir
    codes_cmake \
        -DBOOST_ROOT="${codes_dir[prefix]}" \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make install
}

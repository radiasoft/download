#!/bin/bash

zgoubi_main() {
    codes_dependencies common
    codes_download radiasoft/zgoubi
    # Lots of warnings so disable
    perl -pi -e 's{-Wall}{-w}' CMakeLists.txt
    codes_cmake -DCMAKE_INSTALL_PREFIX:PATH="${codes_dir[prefix]}"
    codes_make_install
}

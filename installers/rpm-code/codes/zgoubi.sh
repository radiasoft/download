#!/bin/bash

zgoubi_python_install() {
    codes_python_install pyzgoubi
}

zgoubi_main() {
    codes_dependencies common
    codes_download radiasoft/zgoubi
    zgoubi_python_versions='2 3'
    # Lots of warnings so disable
    perl -pi -e 's{-Wall}{}' CMakeLists.txt
    codes_cmake -DCMAKE_INSTALL_PREFIX:PATH="${codes_dir[prefix]}"
    codes_make_install
}

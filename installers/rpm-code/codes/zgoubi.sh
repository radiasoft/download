#!/bin/bash

zgoubi_python_install() {
    pip install pyzgoubi
    perl -pi -e "s{(?<=^#\!).*}{$(pyenv which python)}" "$(pyenv which pyzgoubi)"
}

zgoubi_main() {
    codes_dependencies common
    codes_download radiasoft/zgoubi
    zgoubi_python_versions=2
    # Lots of warnings so disable
    perl -pi -e 's{-Wall}{-w}' CMakeLists.txt
    codes_cmake -DCMAKE_INSTALL_PREFIX:PATH="${codes_dir[prefix]}"
    codes_make_install
}

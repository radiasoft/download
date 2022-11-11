#!/bin/bash

ndiff_main() {
    codes_dependencies common
    codes_download quinoacomputing/ndiff
    codes_cmake -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make_install
    # pwd
    # sleep infinity

}
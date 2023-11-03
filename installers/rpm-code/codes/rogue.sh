#!/bin/bash

rogue_main() {
    codes_yum_dependencies zeromq-devel
    codes_dependencies common boost epics
    codes_download slaclab/rogue
    codes_cmake \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D DO_EPICS=1 \
        -D PYTHON_INCLUDE_DIR="$(codes_python_include_dir)" \
        -D PYTHON_LIBRARY="$(codes_python_lib_dir)" \
        -D ROGUE_INSTALL=system
    codes_make
    codes_make_install
}

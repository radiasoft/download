#!/bin/bash

boost_python_install() {
    cd boost_1_72_0
    ./bootstrap.sh --prefix="${codes_dir[prefix]}"
    local p="$(codes_python_include_dir)"
    perl -pi -e "/using python/ && s{;}{: $p ;}" project-config.jam
    # libboost_numpy37.so* and libboost_python37.so* are installed in ~/.local/lib
    # not in ~/.pyenv. This is fine, because these are C++ libraries, and they have
    # the python version in the name
    ./b2 "${CODES_DEBUG_FLAG:+debug}" --without-mpi install
}

boost_main() {
    codes_dependencies common
    codes_download https://boostorg.jfrog.io/artifactory/main/release/1.72.0/source/boost_1_72_0.tar.bz2 '' boost 1.72.0
}

#!/bin/bash

_boost_ver=1.79.0

_boost_dir=boost_${_boost_ver//./_}

# boost 1.72.0 has this problem on gcc11
# https://github.com/boostorg/thread/issues/364
#                 from libs/coroutine/src/posix/stack_traits.cpp:22:
# ./boost/thread/pthread/thread_data.hpp:60:5: error: missing binary operator before token "("

boost_python_install() {
    cd "$_boost_dir"
    ./bootstrap.sh --prefix="${codes_dir[prefix]}"
    local p="$(codes_python_include_dir)"
    perl -pi -e "/using python/ && s{;}{: $p ;}" project-config.jam
    # libboost_numpy*.so* and libboost_python*.so* are installed in ~/.local/lib
    # not in ~/.pyenv. This is fine, because these are C++ libraries, and they have
    # the python version in the name
    ./b2 "${CODES_DEBUG_FLAG:+debug}" --without-mpi install
}

boost_main() {
    codes_dependencies common
    codes_download \
        "https://boostorg.jfrog.io/artifactory/main/release/$_boost_ver/source/$_boost_dir.tar.bz2" \
        '' boost "$_boost_ver"
}

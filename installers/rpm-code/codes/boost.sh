#!/bin/bash

# Fedora 43 has 1.83 but that doesn't compile:
# libs/python/src/numpy/dtype.cpp:101:83: error: ‘PyArray_Descr’ {aka ‘struct _PyArray_Descr’} has no member named ‘elsize’
_boost_ver=1.88.0

_boost_dir=boost_${_boost_ver//./_}

boost_python_install() {
    cd "$_boost_dir"
    ./bootstrap.sh --prefix="${codes_dir[prefix]}" --with-libraries=python
    declare p="$(codes_python_include_dir)"
    perl -pi -e "/using python/ && s{;}{: $p ;}" project-config.jam
    # libboost_numpy*.so* and libboost_python*.so* are installed in ~/.local/lib
    # not in ~/.pyenv. This is fine, because these are C++ libraries, and they have
    # the python version in the name
    ./b2 "${CODES_DEBUG_FLAG:+debug}" --without-mpi install
}

boost_main() {
    codes_dependencies common
    codes_download \
        "https://archives.boost.io/release/$_boost_ver/source/$_boost_dir.tar.bz2" \
        '' boost "$_boost_ver"
}

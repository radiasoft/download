#!/bin/bash

# Fedora 43 has 1.83 but that doesn't compile:
# libs/python/src/numpy/dtype.cpp:101:83: error: ‘PyArray_Descr’ {aka ‘struct _PyArray_Descr’} has no member named ‘elsize’
# Built 1.84 because required by Opal. Disable python below.
_boost_ver=1.84.0

_boost_dir=boost_${_boost_ver//./_}

boost_python_install() {
    cd "$_boost_dir"
    # Disable Python, because it doesn't build with 3.13
    ./bootstrap.sh --prefix="${codes_dir[prefix]}" --without-libraries=python
    ./b2 "${CODES_DEBUG_FLAG:+debug}" --without-mpi --without-python install
}

boost_main() {
    codes_dependencies common
    codes_download \
        "https://archives.boost.io/release/$_boost_ver/source/$_boost_dir.tar.bz2" \
        '' boost "$_boost_ver"
}

#!/bin/bash

xraylib_python_install() {
    codes_download https://github.com/tschoonj/xraylib/releases/download/xraylib-4.2.0/xraylib-4.2.0.tar.xz
    autoreconf -i
    ./configure --prefix="${codes_dir[prefix]}"\
      --disable-idl --disable-java \
      --disable-lua --disable-perl --disable-libtool-lock --disable-ruby \
      --disable-php --enable-python-integration --enable-python --enable-python-numpy
    codes_make
    codes_make_install
}

xraylib_main() {
    codes_yum_dependencies swig
    codes_dependencies common
}

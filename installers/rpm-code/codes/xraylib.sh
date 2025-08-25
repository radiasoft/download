#!/bin/bash

xraylib_main() {
    codes_dependencies common
    codes_download https://github.com/tschoonj/xraylib/releases/download/xraylib-4.1.5/xraylib-4.1.5.tar.xz
    autoreconf -i
    ./configure --prefix="${codes_dir[prefix]}"\
      --disable-idl --disable-java \
      --disable-lua --disable-perl --disable-libtool-lock --disable-ruby \
      --disable-php --with-python-sys-prefix
    codes_make
    codes_make_install
}

#!/bin/bash

xraylib_main() {
    # this is needed for bmad (fortran)
    # and is a duplicate of the xraylib pip install in shadow3.sh
    codes_dependencies common
    codes_download https://github.com/tschoonj/xraylib/releases/download/xraylib-4.2.0/xraylib-4.2.0.tar.xz
    autoreconf -i
    ./configure --prefix="${codes_dir[prefix]}"\
      --disable-idl --disable-java \
      --disable-lua --disable-perl --disable-libtool-lock --disable-ruby \
      --disable-php --disable-python
    codes_make
    codes_make_install
}

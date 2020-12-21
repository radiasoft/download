#!/bin/bash

h5hut_main() {
    codes_dependencies common
    codes_download https://gitlab.psi.ch/H5hut/src/-/archive/H5hut-2.0.0rc6/src-H5hut-2.0.0rc6.tar.bz2
    perl -pi -e 's{\`which}{\`type -p}' autogen.sh
    ./autogen.sh
    perl -pi -e 's{\`which}{\`type -p}' configure
    CC=mpicc CXX=mpicxx ./configure \
      --enable-parallel \
      --prefix="${codes_dir[prefix]}" \
      --with-pic
    codes_make_install
}

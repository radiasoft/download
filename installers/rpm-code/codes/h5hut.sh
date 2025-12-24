#!/bin/bash

h5hut_main() {
    codes_dependencies common
    # rc7 does not compile
    codes_download https://gitea.psi.ch/H5hut/src/archive/H5hut-2.0.0rc6.tar.gz src
    # We are using an updated version of hdf5 which changed the interfaces of these functions.
    # But, h5hut has not updated. So use the old functions (add suffix of 1)
    # https://docs.hdfgroup.org/archive/support/HDF5/doc/RM/APICompatMacros.html
    for f in  $(find . -name '*.c' -o -name '*.h'); do
        for n in 'H5Oget_info' 'H5Oget_info_by_name'; do
            perl -pi -e "s/${n}\b/${n}1/" "$f"
        done
    done
    perl -pi -e 's{\`which}{\`type -p}' autogen.sh
    ./autogen.sh
    perl -pi -e 's{\`which}{\`type -p}' configure
    CC=mpicc CXX=mpicxx CFLAGS='-Wno-incompatible-pointer-types' ./configure \
      --enable-parallel \
      --prefix="${codes_dir[prefix]}" \
      --with-pic
    codes_make_install
}

#!/bin/bash

opencoarrays_main() {
    codes_dependencies common
    codes_download sourceryinstitute/OpenCoarrays
    CC=gcc FC=gfortran \
        codes_cmake -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make install
}

#!/bin/bash

radia_main() {
    # needed for fftw and uti_*.py
    codes_dependencies srw
    codes_download ochubar/Radia
    radia_python_versions='2 3'
    # committed *.so files are not so good.
    find . -name \*.so -o -name \*.a -o -name \*.pyd -exec rm {} \;
    rm -rf ext_lib
    perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
    perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
    cd cpp/gcc
    make "-j$(codes_num_cores)" lib
}

radia_python_install() {
    cd Radia/cpp/py
    make python
    cd ../..
    codes_python_lib_copy env/radia_python/radia*.so
    find . -name radia\*.so -exec rm {} \;
}

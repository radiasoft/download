#!/bin/bash

srw_python_install() {
    cd SRW/cpp/py
    make python
    cd ../..
    codes_python_lib_copy env/work/srw_python/{{srwl,uti}*.py,srwlpy*.so}
    find . -name srwlpy\*.so -exec rm {} \;
}

srw_main() {
    codes_yum_dependencies fftw2-devel
    codes_dependencies bnlcrl
    srw_python_versions='2 3'
    codes_download ochubar/SRW
    # committed *.so files are not so good.
    find . -name \*.so -o -name \*.a -o -name \*.pyd -exec rm {} \;
    perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
    perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
    cd cpp/gcc
    make -j"$(codes_num_cores)" lib
}

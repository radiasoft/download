#!/bin/bash

radia_main() {
    # needed for fftw and uti_*.py
    codes_dependencies srw
    codes_download ochubar/Radia
    radia_python_versions=3
    # committed *.so files are not so good.
    find . -name \*.so -o -name \*.a -o -name \*.pyd -exec rm {} \;
    rm -rf ext_lib
    perl -pi - cpp/py/setup.py <<'EOF'
        s/mpi_cxx/mpicxx/;
        s{/usr/lib/openmpi/lib}{/usr/lib64/mpich/lib}g;
        s{/usr/lib/openmpi/include}{/usr/include/mpich-x86_64}g;
EOF
    perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
    cd cpp/gcc
    make "-j$(codes_num_cores)" lib
}

radia_python_install() {
    cd Radia/cpp/py
    MODE=mpi python setup.py build_ext
    codes_python_lib_copy "$(find . -name radia*.so)"
}

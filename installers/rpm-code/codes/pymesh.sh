#!/bin/bash

pymesh_python_install() {
    cd PyMesh
    NUM_CORES=$(codes_num_cores) codes_python_install
    # run tests outside build directory
    cd ..
    python -c 'import pymesh; pymesh.test()'
}

pymesh_main() {
    codes_yum_dependencies mpfr-devel gmp-devel
    codes_dependencies common boost
    codes_download_nonrecursive=1 codes_download https://github.com/radiasoft/PyMesh.git
    # geogram is far back
    git submodule update --init --depth=50 third_party/geogram
    # fmt is strange, can't specify depth
    git submodule update --init --recursive third_party/fmt
    # cgal is very large so use --depth=5 fmt needs --depth=10
    git submodule update --init --depth=5 $(find third_party/* -maxdepth 0 -type d | egrep -v '(geogram|fmt)')
}

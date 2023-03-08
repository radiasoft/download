#!/bin/bash

graphtool_python_install() {
    cd graph-tool-2.46
    ./configure \
        --enable-openmp \
        --prefix="${codes_dir[pyenv_prefix]}" \
        --with-boost="${codes_dir[prefix]}" \
        --with-cgal="${codes_dir[prefix]}" \
        --disable-cairo
    codes_make_install
}

graphtool_main() {
    codes_yum_dependencies expat-devel graphviz sparsehash-devel
    codes_dependencies common cgal
    codes_download https://downloads.skewed.de/graph-tool/graph-tool-2.46.tar.bz2
}

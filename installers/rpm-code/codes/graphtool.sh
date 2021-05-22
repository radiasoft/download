#!/bin/bash

graphtool_python_install() {
    NUM_CORES=$(codes_num_cores) codes_python_install
    cd graph-tool-2.37
./configure --enable-openmp --prefix=$(pyenv prefix) --with-boost=$HOME/.local --with-cgal=$HOME/.local --disable-cairo

BOOSTLIBDIR=$HOME/.local/lib sh ./configure --enable-openmp --prefix=$(pyenv prefix) --with-boost=$HOME/.local --with-cgal=$HOME/.local --with-boost-python=boost_python37

    ./configure --enable-openmp --prefix="${codes_dir[prefix]}" --docdir="/usr/share/doc/$pkgname"
    codes_make
}

graphtool_main() {
    local x=(
        sparsehash-devel
        graphviz
    )
    codes_yum_dependencies "${x[@]}"
    codes_dependencies common
    codes_download https://downloads.skewed.de/graph-tool/graph-tool-2.37.tar.bz2
}

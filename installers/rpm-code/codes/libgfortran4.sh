#!/bin/bash
libgfortran4_main() {
    codes_dependencies common
    codes_yum_dependencies libmpc-devel
    codes_download https://bigsearcher.com/mirrors/gcc/releases/gcc-7.5.0/gcc-7.5.0.tar.xz
    mkdir ../gcc-build
    cd ../gcc-build
    ../gcc-7.5.0/configure --enable-languages=fortran --enable-checking=release --prefix=$HOME/.local --disable-multilib --disable-bootstrap
    install -m 555 x86_64-pc-linux-gnu/libgfortran/.libs/libgfortran.so.4.0.0 \
            "${codes_dir[lib]}"/libgfortran.so.4
}

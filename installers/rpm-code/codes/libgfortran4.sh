#!/bin/bash
libgfortran4_main() {
    codes_dependencies common
    codes_yum_dependencies libmpc-devel
    codes_download https://bigsearcher.com/mirrors/gcc/releases/gcc-7.5.0/gcc-7.5.0.tar.xz
    cd ..
    local p=$PWD/gcc-install
    mkdir "$p"
    mkdir gcc-build
    cd gcc-build
    ../gcc-7.5.0/configure --enable-languages=fortran --enable-checking=release --prefix="$p" --disable-multilib --disable-bootstrap
    codes_make all
    codes_make_install
    install -m 555 "$p"/lib64/libgfortran.so.4.0.0 "${codes_dir[lib]}"/libgfortran.so.4
}

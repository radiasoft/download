#!/bin/bash

slepc_main() {
    codes_dependencies common petsc
    codes_download https://gitlab.com/slepc/slepc.git release
    export PETSC_DIR=${codes_dir[prefix]} SLEPC_DIR="$PWD"
    ./configure \
        --prefix="${codes_dir[prefix]}"
    codes_make
    codes_make_install
}

slepc_python_install() {
    cd slepc/src/binding/slepc4py
    PETSC_ARCH=linux-gnu SLEPC_DIR=${codes_dir[prefix]} codes_python_install
    unset PETSC_DIR SLEPC_DIR
}

#!/bin/bash

code_base_main() {
    local rpms=(
        atlas-devel
        blas-devel
        boost-static
        cmake
        eigen3-devel
        flex
        glib2-devel
        hdf5-devel
        hdf5-openmpi
        hdf5-openmpi-devel
        hdf5-openmpi-static
        lapack-devel
        libtool
        llvm-libs
        openmpi-devel
        valgrind-devel
    )
    install_yum_install "${rpms[@]}"
}

code_base_main

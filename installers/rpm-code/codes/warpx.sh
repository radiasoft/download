#!/bin/bash

warpx_main() {
    declare -a c=()
    # POSIT: Same version as amrex and pyamrex
    : ${warpx_version:=25.11}
    codes_dependencies common $(codes_nvidia_module amrex) openpmdapi $(codes_nvidia_module pyamrex)
    if [[ ${codes_is_nvidia:-} ]]; then
        # POSIT: oldest gpus are Volta (sm_70)
        c=(
            -D AMReX_CUDA_ARCH=7.0
            -D WarpX_COMPUTE=CUDA
        )
    fi
    codes_download "https://github.com/ECP-WarpX/WarpX/archive/refs/tags/$warpx_version.tar.gz" \
        "warpx-$warpx_version" warpx "$warpx_version"
    CXXFLAGS=-Wno-template-body \
        codes_cmake2 \
        -D WarpX_DIMS='1;2;RZ;3' \
        -D WarpX_PYTHON=ON \
        -D WarpX_amrex_internal=OFF \
        -D WarpX_openpmd_internal=OFF \
        -D WarpX_pyamrex_internal=OFF \
        "${c[@]}"
    codes_cmake_build install
    codes_cmake_build pip_install
}

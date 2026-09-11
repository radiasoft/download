#!/bin/bash

pyamrex_main() {
    declare -a c=()
    # POSIT: Same version as amrex
    : ${pyamrex_version:=25.11}
    codes_dependencies common $(codes_nvidia_module amrex)
    if [[ ${codes_is_nvidia:-} ]]; then
        # POSIT: oldest gpus are Volta (sm_70)
        c=(
            -DAMReX_CUDA_ARCH=7.0
            -DAMReX_GPU_BACKEND=CUDA
        )
    fi
    codes_download "https://github.com/AMReX-Codes/pyamrex/archive/refs/tags/$pyamrex_version.tar.gz" \
        "pyamrex-$pyamrex_version" pyamrex "$pyamrex_version"
    codes_cmake2 -DpyAMReX_amrex_internal=OFF "${c[@]}"
    codes_cmake_build install
    codes_cmake_build pip_install
}

#!/bin/bash

amrex_main() {
    declare -a c=()
    # If this version is changed all dependent codes (pyamrex, impactx, warpx) must be updated.
    : ${amrex_version:=25.11}
    codes_dependencies common
    if [[ ${codes_is_nvidia:-} ]]; then
        # POSIT: oldest gpus are Volta (sm_70)
        c=(
            -DAMReX_CUDA_ARCH=7.0
            -DAMReX_GPU_BACKEND=CUDA
        )
    fi
    codes_download "https://github.com/AMReX-Codes/amrex/releases/download/$amrex_version/amrex-$amrex_version.tar.gz" amrex
    # EB component needed by impactx
    codes_cmake2   \
      -DAMReX_BUILD_SHARED_LIBS=ON  \
      -DAMReX_EB=ON \
      -DAMReX_LINEAR_SOLVERS=ON \
      -DAMReX_MPI_THREAD_MULTIPLE=ON \
      -DAMReX_OMP=ON \
      -DAMReX_PARTICLES=ON \
      -DAMReX_PIC=ON \
      -DAMReX_SPACEDIM="1;2;3" \
      "${c[@]}"
    codes_cmake_build install
}

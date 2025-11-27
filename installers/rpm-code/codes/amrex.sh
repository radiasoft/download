#!/bin/bash

amrex_main() {
    codes_dependencies common
    # If this version is changed all dependent codes (pyamrex, impactx, warpx) must be updated.
    codes_download https://github.com/AMReX-Codes/amrex/releases/download/25.11/amrex-25.11.tar.gz amrex
    # EB component needed by impactx
    codes_cmake2   \
      -DAMReX_BUILD_SHARED_LIBS=ON  \
      -DAMReX_EB=ON \
      -DAMReX_LINEAR_SOLVERS=ON \
      -DAMReX_MPI_THREAD_MULTIPLE=ON \
      -DAMReX_OMP=ON \
      -DAMReX_PARTICLES=ON \
      -DAMReX_PIC=ON \
      -DAMReX_SPACEDIM="1;2;3"
    codes_cmake_build install
}

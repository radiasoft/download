#!/bin/bash

amrex_main() {
    codes_dependencies common
    # If this version is changed all dependent codes (pyamrex, impactx, warpx) must be updated.
    codes_download https://github.com/AMReX-Codes/amrex/releases/download/24.09/amrex-24.09.tar.gz amrex
    # AMReX_TINY_PROFILE=ON added because of https://github.com/ECP-WarpX/WarpX/issues/5295
    codes_cmake2   \
      -DAMReX_BUILD_SHARED_LIBS=ON  \
      -DAMReX_LINEAR_SOLVERS=ON \
      -DAMReX_MPI_THREAD_MULTIPLE=ON \
      -DAMReX_OMP=ON \
      -DAMReX_PARTICLES=ON \
      -DAMReX_PIC=ON \
      -DAMReX_SPACEDIM="1;2;3" \
      -DAMReX_TINY_PROFILE=ON \
      -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_cmake_build install
}

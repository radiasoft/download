#!/bin/bash

amrex_main() {
    codes_dependencies common
    codes_download https://github.com/AMReX-Codes/amrex/releases/download/24.05/amrex-24.05.tar.gz amrex
    codes_cmake2   \
      -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"  \
      -DAMReX_BUILD_SHARED_LIBS=ON  \
      -DAMReX_LINEAR_SOLVERS=ON     \
      -DAMReX_MPI_THREAD_MULTIPLE=ON  \
      -DAMReX_OMP=ON                \
      -DAMReX_PARTICLES=ON          \
      -DAMReX_SPACEDIM="1;2;3"
    codes_cmake_build install
}

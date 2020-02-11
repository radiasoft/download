#!/bin/bash
codes_dependencies trilinos H5hut
codes_download https://gitlab.psi.ch/OPAL/src/-/archive/OPAL-2.2.0/src-OPAL-2.2.0.tar.gz
CMAKE_PREFIX_PATH="${codes_dir[prefix]}" H5HUT_PREFIX="${codes_dir[prefix]}" \
    HDF5_INCLUDE_DIR=/usr/include \
    HDF5_LIBRARY_DIR="$BIVIO_MPI_LIB" \
    CC=mpicc CXX=mpicxx \
    codes_cmake \
    --prefix="${codes_dir[prefix]}" \
    -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
    -DENABLE_SAAMG_SOLVER=TRUE
codes_make_install

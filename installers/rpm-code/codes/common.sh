#!/bin/bash
# Some rpms most codes use
_common_yum=(
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
)
codes_yum_dependencies "${_common_yum[@]}"
pip install numpy
pip install matplotlib
pip install scipy
MPICC="$(type -p mpicc)" pip install mpi4py
pip install Cython
# Force MPI mode (not auto-detected)
CC="$(type -p mpicc)" HDF5_MPI=ON pip install --no-binary=h5py h5py
pip install tables==3.3.0

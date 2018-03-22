#!/bin/bash
# This probably needs to be first
codes_dependencies mpi4py
# Need to install Cython first, or h5py build fails
pip install Cython
# Force MPI mode (not auto-detected)
CC="$(type -p mpicc)" HDF5_MPI=ON pip install --no-binary=h5py h5py

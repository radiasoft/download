#!/bin/bash
pip install numpy
pip install matplotlib
pip install scipy
MPICC="$(type -p mpicc)" pip install mpi4py
pip install Cython
# Force MPI mode (not auto-detected)
CC="$(type -p mpicc)" HDF5_MPI=ON pip install --no-binary=h5py h5py
pip install tables==3.3.0
# Lots of dependencies so we install here to avoid rpm collisions.
# Slows down builds of pykern, but doesn't affect development.
codes_download pykern
codes_python_install
_common_pp=$(pyenv prefix)
# otherwise directories are owned by root
rpm_code_build_include_add "$_common_pp/share" "$_common_pp/man"

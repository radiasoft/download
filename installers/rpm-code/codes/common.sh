#!/bin/bash
common_main() {
    pip install numpy
    pip install matplotlib
    pip install scipy
    # used by synergia and has man/man1 duplicate problem so just include here
    pip install nose
    MPICC="$(type -p mpicc)" pip install mpi4py
    pip install Cython
    # Force MPI mode (not auto-detected)
    CC="$(type -p mpicc)" HDF5_MPI=ON pip install --no-binary=h5py h5py
    pip install tables==3.3.0
    # Lots of dependencies so we install here to avoid rpm collisions.
    # Slows down builds of pykern, but doesn't affect development.
    codes_download pykern
    codes_python_install
    local pp=$(pyenv prefix)
    local i f
    for i in share man; do
        # otherwise directories are owned by root
        f=$pp/$i
        mkdir -p "$f"
        rpm_code_build_include_add "$f"
    done
}

common_main

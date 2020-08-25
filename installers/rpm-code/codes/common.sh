#!/bin/bash

common_python() {
    local v=$1
    local prev_d=$PWD
    local mpicc=$(type -p mpicc)
    if [[ ! $mpicc ]]; then
        install_err mpicc not found
    fi
    MAKE_OPTS=-j$(codes_num_cores) bivio_pyenv_"$v"
    # Need to set here
    codes_dir[pyenv_prefix]=$(realpath "$(pyenv prefix)")
    pip install mpi4py
    pip install numpy
    pip install matplotlib
    pip install scipy
    # used by synergia and has man/man1 duplicate problem so just include here
    pip install nose
    pip install Cython
    # Force MPI mode (not auto-detected)
    CC=$mpicc HDF5_MPI=ON pip install --no-binary=h5py h5py
    # install Pillow (PIL), needed by srw and scikit-image and
    # something else below
    pip install \
        pandas \
        python-dateutil \
        tables \
        Pillow
    # Lots of dependencies so we install here to avoid rpm collisions.
    # Slows down builds of pykern, but doesn't affect development.
    codes_download pykern
    codes_python_install
    # xraylib puts files in include; needs to be in common
    # https://github.com/radiasoft/containers/issues/92
    install -d -m 755 "${codes_dir[pyenv_prefix]}"/include
    cd "$prev_d"
    rm -f "${codes_dir[pyenv_prefix]}"/cache/*
}

common_main() {
    local mpi=mpich
    if [[ $mpi =~ local ]]; then
        install_err 'need to install mpi versions of hdf5 and fftw'
    fi
    local rpms=(
        $mpi-devel
        blas-devel
        cmake
        fftw-$mpi-devel
        flex
        gcc-gfortran
        glib2-devel
        hdf5-$mpi
        hdf5-$mpi-devel
        hdf5-$mpi-static
        hdf5-devel
        lapack-devel
        # https://bugs.python.org/issue31652
        libffi-devel
        libtool
        llvm-libs
        nodejs
        valgrind-devel
    )
    codes_yum_dependencies "${rpms[@]}"
    install_source_bashrc
    common_python 3
    # codes install into "lib/cmake" which needs to be owned by common
    install -d -m 755 "${codes_dir[lib]}"/cmake
}

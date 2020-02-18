#!/bin/bash

common_python() {
    local v=$1
    local prev_d=$PWD
    local mpicc=$(type -p mpicc)
    if [[ ! $mpicc ]]; then
        install_err mpicc not found
    fi
    MAKE_OPTS=-j$(codes_num_cores) bivio_pyenv_"$v"
    pip install mpi4py
    pip install numpy
    pip install matplotlib
    pip install scipy
    # used by synergia and has man/man1 duplicate problem so just include here
    pip install nose
    pip install Cython
    # Force MPI mode (not auto-detected)
    CC=$mpicc HDF5_MPI=ON pip install --no-binary=h5py h5py
    pip install tables
    # Lots of dependencies so we install here to avoid rpm collisions.
    # Slows down builds of pykern, but doesn't affect development.
    codes_download pykern
    codes_python_install
    cd "$prev_d"
}

common_main() {
    local mpi=mpich
    local rpms=(
        atlas-devel
        blas-devel
        boost-devel
        boost-python2-devel
        boost-static
        cmake
        eigen3-devel
        flex
        glib2-devel
        graphviz
        lapack-devel
        # https://bugs.python.org/issue31652
        libffi-devel
        libtool
        llvm-libs
        valgrind-devel
    )
    if [[ $mpi =~ local ]]; then
        install_err 'need to install mpi versions of hdf5 and fftw'
    else
        rpms+=(
            $mpi-devel
            fftw-$mpi-devel
            hdf5-devel
            hdf5-$mpi
            hdf5-$mpi-devel
            hdf5-$mpi-static
        )
    fi
    codes_yum_dependencies "${rpms[@]}"
    install_source_bashrc
    # after rpm installs, required for builds
    # py3 is first, because bivio_pyenv_[23] sets global version
    common_python 3
    local codes_download_reuse_git=1
    common_python 2
    rpm_code_build_include_add "$(pyenv root)" "${codes_dir[prefix]}"
}

#!/bin/bash

common_python() {
    local v=$1
    local prev_d=$PWD
    MAKE_OPTS=-j$(codes_num_cores) bivio_pyenv_"$v"
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
    cd "$prev_d"
}

common_main() {
    local rpms=(
        atlas-devel
        blas-devel
        boost-devel
        boost-python2-devel
        boost-static
        cmake
        eigen3-devel
        flex
        fftw-openmpi-devel
        glib2-devel
        hdf5-devel
        hdf5-openmpi
        hdf5-openmpi-devel
        hdf5-openmpi-static
        lapack-devel
        libtool
        llvm-libs
        openmpi-devel
        ruby-devel
        valgrind-devel
    )
    codes_yum_dependencies "${rpms[@]}"
    install_source_bashrc
    gem install --no-document fpm
    # after rpm installs, required for builds
    # py3 is first, because bivio_pyenv_[23] sets global version
    common_python 3
    local codes_download_reuse_git=1
    common_python 2
    # Unlike other rscode RPMs, common owns ~/.pyenv
    rpm_code_build_include_add "$(pyenv root)" "$HOME"/.gem "$HOME"/bin/fpm
    rpm_code_build_exclude_add "$HOME"/bin
}

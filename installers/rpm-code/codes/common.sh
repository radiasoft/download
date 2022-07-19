#!/bin/bash

common_python() {
    local v=$1
    local prev_d=$PWD
    local mpicc=$(type -p mpicc)
    if [[ ! $mpicc ]]; then
        install_err mpicc not found
    fi
    MAKE_OPTS=-j$(codes_num_cores) bivio_pyenv_"$v"
    install_source_bashrc
    # Need to set here
    codes_dir[pyenv_prefix]=$(realpath "$(pyenv prefix)")
    local -a d=(
        mpi4py
        numpy
        matplotlib==3.3.3
        scipy
        # used by synergia and has man/man1 duplicate problem so just include here
        nose
        Cython
    )
    install_pip_install "${d[@]}"
    # Force MPI mode (not auto-detected)
    CC=$mpicc HDF5_MPI=ON install_pip_install --no-binary=h5py h5py
    d=(
        # pillow and python-dateutil installed by matplotlib
        # pipdeptree is useful for debugging
        pipdeptree
        pandas
        sympy
        tables

        # Conflict between rscode-pyzgoubi and rscode-ml so just include here
        PyYAML

        # Needed by rscode-bluesky and rscode-ml
        cachetools
        scikit-image==0.18.3
        tifffile

        # Needed by rscode-bluesky and rscode-rsbeams
        # https://github.com/jupyter/notebook/issues/2435
        # yt (in rscode-rsbeams) installs jedi, which needs to be forced to 0.17.2
        # keep consistent with container-beamsim-jupyter
        dill
        ipython
        jedi==0.17.2
        parso
        prompt_toolkit

        # fortran namelist parser, usable by many codes
        f90nml
        # Conflict between rscode-bluesky and rscode-openpmd
        tqdm
        astunparse==1.6.3

        #conflict between rscode-mantid and rscode-ml
        # version needs to be tensorflow_2_3_1_deps (see ml.sh)
        'wrapt>=1.11.1'
    )
    install_pip_install "${d[@]}"

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
    install_repo_eval fedora-patches
    install_source_bashrc
    common_python 3
    # codes install into "lib/cmake" which needs to be owned by common
    install -d -m 755 "${codes_dir[lib]}"/cmake
}

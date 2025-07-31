#!/bin/bash

_common_h5py() {
    # hdf5, h5py, and  tensorflow all need to agree with each other.
    # We install hdf5 with whatever the latest version from the fedora repos is.
    # We then must backtrack to see what h5py version supports that. They'll mention it in their
    # "What's New" docs https://docs.h5py.org/en/latest/whatsnew/index.html
    # We then must find a tensorflow version that complies. tensorflow/tools/pip_package/setup.py
    # will list the h5py versions that tensorflow supports

    declare p="$PWD"
    # https://git.radiasoft.org/download/issues/422
    codes_download h5py/h5py 3.10.0
    declare mpicc=$(type -p mpicc)
    if [[ ! $mpicc ]]; then
        install_err mpicc not found
    fi
    # Force MPI mode (not auto-detected)
    CC=$mpicc HDF5_MPI=ON install_pip_install --no-binary=h5py .
    cd "$p"
}

_common_nvm() {
    PROFILE=/dev/null codes_download https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh '' nvm 0.40.3
    install_source_bashrc
    npm install node
}

_common_python() {
    declare prev_d=$PWD
    MAKE_OPTS=-j$(codes_num_cores) install_repo_eval pyenv
    install_source_bashrc
    # Need to set here
    codes_dir[pyenv_prefix]=$(realpath "$(pyenv prefix)")
    declare -a d=(
        mpi4py
        # https://github.com/radiasoft/download/issues/627
        'numpy==1.23.5'
        # required by cmyt 1.3.0 (required by yt)
        # https://github.com/radiasoft/download/issues/497
        'matplotlib>=3.5.0'
        scipy
        Cython
    )
    install_pip_install "${d[@]}"
    _common_h5py
    d=(
        # Needed by omega
        openpmd-beamphysics

        # pillow and python-dateutil installed by matplotlib
        # pipdeptree is useful for debugging
        pipdeptree

        # tfs-pandas (required by sirepo-bluesky which is required by rscode-bluesky)
        'pandas>=2.0,<2.1.0'
        sympy
        tables

        # Conflict between rscode-pyzgoubi and rscode-ml so just include here
        PyYAML

        # Needed by rscode-bluesky and rscode-ml
        cachetools
        lxml
        pydantic
        scikit-image==0.18.3
        tifffile
        typing-extensions
        tzdata


        # Needed by rscode-bluesky and rscode-rsbeams
        # https://github.com/jupyter/notebook/issues/2435
        # yt (in rscode-rsbeams) installs jedi, which needs to be forced to 0.17.2
        # keep consistent with container-beamsim-jupyter
        dill
        ipython
        jedi==0.17.2
        parso
        prompt_toolkit
        fsspec

        # Needed by rscode-bluesky and rscode-impactt
        pint

        # conflict between warpx and bnlcrl
        periodictable

        # conflict between rscode-bluesky and rscode-rsbeams
        unyt

        # fortran namelist parser, usable by many codes
        f90nml
        # Conflict between rscode-bluesky and rscode-openpmd
        tqdm
        astunparse==1.6.3

        #conflict between rscode-mantid and rscode-ml
        # version needs to be tensorflow_2_3_1_deps (see ml.sh)
        'wrapt>=1.11.1'

        # conflict between rscode-bluesky and rscode-openmc
        asteval
        jsonschema
        tenacity
        toolz
        tzlocal
        uncertainties

        # conflict between rscode-openmc and rscode-ml
        protobuf

        # conflict between rscode-openmc and rscode-radia
        trimesh

        # conflict between rscode-rsbeams and rscode-ipykernel
        ipykernel

        # conflict between rsbeams and cadopenmc
        nlopt
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
    declare mpi=mpich
    declare rpms=(
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
        valgrind-devel
    )
    if ! install_version_fedora_lt_36; then
        rpms+=('perl-FindBin')
    fi
    codes_yum_dependencies "${rpms[@]}"
    install_repo_eval fedora-patches
    install_source_bashrc
    _common_python
    # codes install into "lib/cmake" which needs to be owned by common
    install -d -m 755 "${codes_dir[lib]}"/cmake
}

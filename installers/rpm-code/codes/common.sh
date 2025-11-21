#!/bin/bash

_common_h5py() {
    # hdf5, h5py, and  tensorflow all need to agree with each other.
    # We install hdf5 with whatever the latest version from the fedora repos is.
    # We then must backtrack to see what h5py version supports that. They'll mention it in their
    # "What's New" docs https://docs.h5py.org/en/latest/whatsnew/index.html
    # We then must find a tensorflow version that complies. tensorflow/tools/pip_package/setup.py
    # will list the h5py versions that tensorflow supports

    declare p="$PWD"
    codes_download h5py/h5py 3.15.1
    declare mpicc=$(type -p mpicc)
    if [[ ! $mpicc ]]; then
        install_err mpicc not found
    fi
    # Force MPI mode (not auto-detected)
    CC=$mpicc HDF5_MPI=ON install_pip_install --no-binary=h5py .
    cd "$p"
}

_common_nvm() {
    # Required when NVM_DIR is set
    mkdir -p "$NVM_DIR"
    PROFILE=/dev/null codes_download https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh '' nvm 0.40.3
    install_source_bashrc
    #TODO(pjm): fixed version of node until sirepo #725 is fixed
    #nvm install node
    nvm install 24.5.0
}

_common_python() {
    declare prev_d=$PWD
    MAKE_OPTS=-j$(codes_num_cores) install_repo_eval pyenv
    install_source_bashrc
    install_pip_install --upgrade pip
    # Need to set here
    codes_dir[pyenv_prefix]=$(realpath "$(pyenv prefix)")
    declare -a d=(
        #TODO(robnagler) 3.1.6 doesn't compile with py3.13,
        # https://github.com/radiasoft/download/issues/813
        #'mpi4py==3.1.6'
        mpi4py
        # tensorflow==2.20.0 requires numpy 2.2.6
        numpy=2.2.6
        # required by cmyt 1.3.0 (required by yt)
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

        'pandas>=2.0'
        # torch==2.9.1 requires sympy>=1.13.3
        'sympy>=1.13.3'

        # Conflict between rscode-pyzgoubi and rscode-ml so just include here
        PyYAML

        # Needed by rscode-ml
        cachetools
        lxml
        pydantic
        #TODO(robnagler) was scikit-image==0.18.3
        scikit-image
        tifffile
        typing-extensions
        tzdata


        # Needed by rscode-rsbeams
        # https://github.com/jupyter/notebook/issues/2435
        # yt (in rscode-rsbeams) installs jedi, which needs to be forced to 0.17.2
        # keep consistent with container-beamsim-jupyter
        dill
        httpx
        ipython
        # jedi==0.17.2
        jedi
        parso
        prompt_toolkit
        fsspec

        # Needed by rscode-impactt
        pint

        # conflict between warpx and bnlcrl
        periodictable

        # Needed by rscode-rsbeams
        unyt

        # fortran namelist parser, usable by many codes
        # fixed version because 1.5 writes to /tests which causes a rpm conflict
        #TODO(robnagler) f90nml==1.4.4
        f90nml
        # Needed by rscode-openpmd
        tqdm
        #TODO(robnagler) astunparse==1.6.3
        astunparse

        #conflict between rscode-mantid and rscode-ml
        # version needs to be tensorflow_2_3_1_deps (see ml.sh)
        'wrapt>=1.11.1'

        # Needed by rscode-openmc
        asteval
        jsonschema
        tenacity
        toolz
        tzlocal
        uncertainties

        # Needed by rscode-impactt
        prettytable

        # conflict between rscode-openmc and rscode-ml
        protobuf

        # conflict between rscode-openmc and rscode-radia
        trimesh

        # conflict between rscode-rsbeams and rscode-ipykernel
        ipykernel

        # conflict between rsbeams and cadopenmc
        #TODO(robnagler) upgrade to for numpy 2.x nlopt==2.7.1
        nlopt
    )
    install_pip_install "${d[@]}"
    # Otherwise compile errors for strdup (gnu11), BLOSC/2 don't compile either
    PYTABLES_NO_EMBEDDED_LIBS=1 CFLAGS=-std=gnu11 BLOSC_DIR=/usr BLOSC2_DIR=/usr pip install tables

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
        # python tables
        blosc-devel
        blosc2-devel
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
        libatomic
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
    _common_nvm
    _common_python
    # codes install into "lib/cmake" which needs to be owned by common
    install -d -m 755 "${codes_dir[lib]}"/cmake
}

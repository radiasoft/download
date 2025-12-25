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
    # POSIT: same as container-jupyter
    # Required to exist when NVM_DIR is set
    mkdir -p "$NVM_DIR"
    PROFILE=/dev/null codes_download https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh '' nvm 0.40.3
    install_source_bashrc
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
        # tensorflow==2.20.0 requires numpy 2.2.6
        'numpy==2.2.6'
        # required by cmyt 1.3.0 (required by yt)
        'matplotlib==3.10.7'
        scipy
        Cython
    )
    install_pip_install "${d[@]}"
    _common_h5py
    # Necessary, because mpi4py vendors openmpi and mpich
    install_pip_install --no-binary=mpi4py mpi4py==4.1.1
    d=(
        # Needed by a number of codes
        'pydantic==2.12.4'
        'pydantic_core==2.41.5'
        'pydantic-settings==2.12.0'
        'typing-extensions==4.15.0'
        'prettytable==3.17.0'

        # genesis4 and impactt
        'eval_type_backport==0.3.0'
        'lark==1.3.1'
        'lume-base==0.3.3'

        # impactt
        'polars-lts-cpu==1.33.1'

        # Needed by omega
        'openpmd-beamphysics==0.10.2'

        # pillow and python-dateutil installed by matplotlib
        # pipdeptree is useful for debugging
        'pipdeptree==2.30.0'

        'pandas==2.3.3'
        # torch==2.9.1 requires sympy>=1.13.3
        'sympy==1.14.0'

        # Needed by rscode-ml so just include here
        'PyYAML==6.0.3'

        # Needed by rscode-ml
        'cachetools==6.2.2'
        'lxml==6.0.2'

        #TODO(robnagler) was scikit-image==0.18.3
        'scikit-image==0.25.2'
        'tifffile==2025.10.16'
        'tzdata==2025.2'

        # Needed by fenics and shadow
        'scikit_build_core==0.11.6'

        # Needed by fenics
        'nanobind==2.9.2'

        # Sirepo and genesis4/lume
        'Jinja2==3.1.6'
        'psutil==7.1.3'

        # Needed by rscode-rsbeams
        # https://github.com/jupyter/notebook/issues/2435
        # yt (in rscode-rsbeams) installs jedi, which needs to be forced to 0.17.2
        # keep consistent with container-beamsim-jupyter
        'dill==0.4.0'
        'httpx==0.28.1'
        'ipython==9.8.0'
        # jedi==0.17.2
        'jedi==0.19.2'
        'parso==0.8.5'
        'prompt_toolkit==3.0.52'
        'fsspec==2025.10.0'

        # Needed by rscode-impactt
        'pint==0.25.2'

        # conflict between warpx and bnlcrl
        # pywarpx 25.11 requires periodictable~=1.5
        'periodictable==2.0.2'

        # Needed by rscode-rsbeams
        'unyt==3.0.4'

        # fortran namelist parser, usable by many codes
        # fixed version because 1.5 writes to /tests which causes a rpm conflict
        #TODO(robnagler) f90nml==1.4.4
        'f90nml==1.5.0'
        # Needed by rscode-openpmd
        'tqdm==4.67.1'
        'astunparse==1.6.3'

        #conflict between rscode-mantid and rscode-ml
        # version needs to be tensorflow_2_3_1_deps (see ml.sh)
        'wrapt==2.0.1'

        # Needed by rscode-openmc
        'asteval==1.0.7'
        'jsonschema==4.25.1'
        'tenacity==9.1.2'
        'toolz==1.1.0'
        'tzlocal==5.3.1'
        'uncertainties==3.2.3'

        # conflict between rscode-openmc and rscode-ml
        'protobuf==6.33.1'

        # conflict between rscode-openmc and rscode-radia
        'trimesh==4.9.0'

        # conflict between rsbeams and cadopenmc
        #TODO(robnagler) upgrade to for numpy 2.x nlopt==2.7.1
        'nlopt==2.9.1'
    )
    install_pip_install "${d[@]}"
    # Otherwise compile errors for strdup (gnu11), BLOSC/2 don't compile either
    PYTABLES_NO_EMBEDDED_LIBS=1 CFLAGS=-std=gnu11 BLOSC_DIR=/usr BLOSC2_DIR=/usr pip install tables==3.10.2

    # Lots of dependencies so we install here to avoid rpm collisions.
    # Slows down builds of pykern, but doesn't affect development.
    codes_download pykern
    codes_python_install
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
        perl-FindBin
        valgrind-devel
    )
    codes_yum_dependencies "${rpms[@]}"
    install_repo_eval fedora-patches
    install_source_bashrc
    _common_nvm
    _common_python
    # codes install into "lib/cmake" which needs to be owned by common
    install -d -m 755 "${codes_dir[lib]}"/cmake
}

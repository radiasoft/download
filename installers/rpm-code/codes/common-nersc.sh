#!/bin/bash

_common_nersc_h5py() {
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

common_nersc_main() {
    # POSIT: installers/code
    if [[ ! -e /etc/yum.repos.d/radiasoft.repo ]]; then
        install_yum_add_repo "$install_depot_server/yum/$install_os_release_id/$install_os_release_version_id/$(arch)/dev/radiasoft.repo"
    fi
    # all rpms required by mpich must be here
    declare rpms=(
        # https://bugs.python.org/issue31652
        cmake
        fftw-devel
        gcc-fortran
        glib2-devel
        hdf5-devel
        lapack-devel
        libatomic
        libffi-devel
        libtool
        llvm-libs
        hwloc
    )
    codes_yum_dependencies "${rpms[@]}"
    codes_yum_dependencies --disablerepo='*' --enablerepo=radiasoft-dev mpich mpich-devel
    # _common_nersc_mpich
    install_repo_eval fedora-patches
    install_source_bashrc
    # so mpich gets in path
    install_source_bashrc
    _common_nersc_python
    _common_nersc_srw
    # codes install into "lib/cmake" which needs to be owned by common
    install -d -m 755 "${codes_dir[lib]}"/cmake
}

# _common_nersc_mpich() {
#     # Needs to be here for bashrc
#     declare p=/usr/lib64/mpich
#     rpm_code_root_dirs+=( $p )
#     codes_download https://github.com/pmodels/mpich/releases/download/v3.4.3/mpich-3.4.3.tar.gz
#     install_sudo bash <<EOF
#         set -eou pipefail
#         umask 022
#         set -x
#         declare -a CONFIGURE_OPTS=(
#             --with-custom-version-string=3.4.3
#             --enable-sharedlibs=gcc
#             --enable-shared
#             --enable-static=no
#             --enable-lib-depend
#             --disable-rpath
#             --disable-silent-rules
#             --disable-fortran
#             --with-gnu-ld
#             --with-device=ch3:nemesis
#             --with-pm=hydra:gforker
#             --prefix=$p
#             --with-hwloc-prefix=system
#             --with-libfabric=system
#             --with-ucx=system
#         )
#         # --enable-fortran FFLAGS=-fallow-argument-mismatch
#         export LN_S='ln -s'
#         ./configure "\${CONFIGURE_OPTS[@]}"
#         make -j$(codes_num_cores)
#         make install
# EOF
#     cd ..
#     ls -al $p $p/bin
# }

_common_nersc_python() {
    declare prev_d=$PWD
    MAKE_OPTS=-j$(codes_num_cores) install_repo_eval pyenv
    install_pip_install --upgrade pip
    # Need to set here
    codes_dir[pyenv_prefix]=$(realpath "$(pyenv prefix)")
    declare -a d=(
        # tensorflow==2.20.0 requires numpy 2.2.6
        'numpy==2.2.6'
        # required by cmyt 1.3.0 (required by yt)
        'matplotlib==3.10.7'
        'h5py==3.15.1',
    )
    install_pip_install "${d[@]}"
    # Necessary, because mpi4py vendors openmpi and mpich
    install_pip_install --no-binary=mpi4py mpi4py==4.1.1
    # _common_nersc_h5py wihtout mpi support
    d=(
        # Sirepo and genesis4/lume
        'Jinja2==3.1.6'
        'psutil==7.1.3'
    )
    install_pip_install "${d[@]}"
    cd "$prev_d"
    rm -f "${codes_dir[pyenv_prefix]}"/cache/*
}

_common_nersc_srw() {
    declare prev_d=$PWD
    codes_download radiasoft/bnlcrl pyproject
    codes_python_install
    install_pip_install primme==3.2.3 srwpy==4.1.1
    # Remove when merged: https://github.com/ochubar/SRW/pull/57
    declare d=$(codes_python_lib_dir)
    cd "$d/srwpy"
    declare -a f=( srwlib.py uti_io.py srwl_bl.py )
    chmod u+w "${f[@]}"
    perl -pi -e 's{\brepr\(}{str(}g' "${f[@]}"
    chmod u-w "${f[@]}"
    cd "$prev_d"
}

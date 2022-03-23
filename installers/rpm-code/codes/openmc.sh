#!/bin/bash

openmc_dagmc() {
    codes_download svalinn/DAGMC develop
    codes_cmake \
        -D BUILD_STATIC_LIBS=OFF \
        -D BUILD_TALLY=ON \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D MOAB_DIR="${codes_dir[prefix]}"
    codes_make
    codes_make_install
}

openmc_main() {
    codes_yum_dependencies eigen3-devel
    codes_dependencies common
    openmc_moab
    openmc_dagmc
    openmc_openmc
}

openmc_moab() {
    codes_download https://bitbucket.org/fathomteam/moab.git Version5.1.0
    codes_cmake_fix_lib_dir
    codes_cmake \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D ENABLE_HDF5=ON \
        -D HDF5_INCLUDE_DIR="${codes_dir[prefix]}" \
        -D HDF5_ROOT="$BIVIO_MPI_LIB"
    codes_make
    codes_make_install
}

openmc_openmc() {
    codes_download openmc-dev/openmc develop
    codes_cmake_fix_lib_dir
    CXX=mpicxx codes_cmake \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D HDF5_INCLUDE_DIRS="${codes_dir[prefix]}" \
        -D HDF5_PREFER_PARALLEL=on \
        -D OPENMC_USE_DAGMC=on
    codes_make
    codes_make_install
}

openmc_python_install() {
    install_pip_install git+https://github.com/openmc-dev/openmc.git@develop
}

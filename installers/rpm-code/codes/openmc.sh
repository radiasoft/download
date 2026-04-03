#!/bin/bash

openmc_dagmc() {
    declare p="$PWD"
    codes_download svalinn/DAGMC develop
    CC=mpicc CXX=mpicxx codes_cmake2 \
        -D BUILD_STATIC_LIBS=OFF \
        -D BUILD_TALLY=ON \
        -D DOUBLE_DOWN=OFF \
        -D DOUBLE_DOWN_DIR="${codes_dir[prefix]}" \
        -D MOAB_DIR="${codes_dir[prefix]}"
    codes_cmake_build install
    cd "$p"
}

UNUSED_openmc_double_down() {
    declare p="$PWD"
    codes_download pshriwise/double-down v1.1.0
    perl -pi -e 's{avx2}{avx}; s{-march=native}{}' CMakeLists.txt
    codes_cmake2 -D MOAB_DIR="${codes_dir[prefix]}"
    codes_cmake_build install
    cd "$p"
}

openmc_main() {
    codes_yum_dependencies eigen3-devel
    codes_dependencies common # embree
    openmc_moab
    # openmc_double_down
    openmc_dagmc
    openmc_openmc
}

openmc_moab() {
    declare p="$PWD"
    codes_download https://bitbucket.org/fathomteam/moab.git
    CC=mpicc CXX=mpicxx codes_cmake2 \
        -D BUILD_SHARED_LIBS=ON \
        -D ENABLE_HDF5=ON \
        -D ENABLE_MPI=ON \
        -D MPI_HOME="$(dirname $(dirname $(type -p mpicxx)))" \
        -D ENABLE_PYMOAB=ON
    codes_cmake_build install
    cd "$p"
}


openmc_openmc() {
    codes_download openmc-dev/openmc master
    CC=mpicc CXX=mpicxx codes_cmake2 \
        -D HDF5_PREFER_PARALLEL=on \
        -D OPENMC_USE_DAGMC=on \
        -D OPENMC_USE_MPI=on
    codes_cmake_build install
}

openmc_python_install() {
    cd openmc
    codes_python_install
    cd ../moab/build
    codes_python_install
    # allow the last three to float
    declare -a x=(
        'neutronics_material_maker[density]==1.2.1'
        'pymeshlab==2025.7'
        'vtk==9.5.2'
        # Allow these versions to float, because we are using develop branch
        'dagmc_geometry_slice_plotter'
        'openmc-data-downloader'
        'git+https://github.com/svalinn/pydagmc.git'
    )
    install_pip_install "${x[@]}"
}

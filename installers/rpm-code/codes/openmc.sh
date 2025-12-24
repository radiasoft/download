#!/bin/bash

openmc_dagmc() {
    local p="$PWD"
    codes_download svalinn/DAGMC develop
    CC=mpicc CXX=mpicxx codes_cmake2 \
        -D BUILD_STATIC_LIBS=OFF \
        -D BUILD_TALLY=ON \
        -D MOAB_DIR="${codes_dir[prefix]}"
    codes_cmake_build install
    cd "$p"
}

openmc_main() {
    codes_yum_dependencies eigen3-devel
    codes_dependencies common
    openmc_moab
    openmc_dagmc
    openmc_openmc
}

openmc_moab() {
    local p="$PWD"
    # 20230827 fixes pymoab/core.pyx:1509:48: no suitable method found
    codes_download https://bitbucket.org/fathomteam/moab.git # bfccfc78e6cb3ddc02c39be437a64696bf126d86
    # This cmake module uses python-config which doesn't work with venv
    # https://mail.python.org/archives/list/python-ideas@python.org/thread/QTCPOM5YBOKCWWNPDP7Z4QL2K6OWGSHL/
    # So, just use native cmake find_package(PythonLibs) which
    # does the same thing
#    echo 'find_package(PythonLibs REQUIRED)' > pymoab/cmake/FindPythonDev.cmake
    CC=mpicc CXX=mpicxx codes_cmake2 \
        -D BUILD_SHARED_LIBS=ON \
        -D ENABLE_HDF5=ON \
        -D ENABLE_MPI=ON \
        -D MPI_HOME="$(dirname $(dirname $(type -p mpicxx)))" \
        -D ENABLE_PYMOAB=ON \
        -D PYTHON_INCLUDE_DIR="$(codes_python_include_dir)"\
        -D PYTHON_LIBRARY="$(codes_python_lib_dir)"
    codes_cmake_build install
    cd "$p"
}

openmc_openmc() {
    # Python 3.9 support was dropped a few commits after this. The
    # commits directly before 3.9 support being dropped all showed
    # broken builds. This was the first one to show a successful
    # build.
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

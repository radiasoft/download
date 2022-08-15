#!/bin/bash

openmc_dagmc() {
    local p="$PWD"
    codes_download svalinn/DAGMC "$version"
    codes_cmake \
        -D BUILD_STATIC_LIBS=OFF \
        -D BUILD_TALLY=ON \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D MOAB_DIR="${codes_dir[prefix]}"
    codes_make
    codes_make_install
    cd "$p"
}

openmc_main() {
    codes_yum_dependencies eigen3-devel
    codes_dependencies common
    openmc_moab
    version=develop
    openmc_dagmc
    openmc_openmc
}

openmc_moab() {
    local p="$PWD"
    codes_download https://bitbucket.org/fathomteam/moab.git Version5.1.0
    codes_cmake_fix_lib_dir
    # This cmake module uses python-config which doesn't work with venv
    # https://mail.python.org/archives/list/python-ideas@python.org/thread/QTCPOM5YBOKCWWNPDP7Z4QL2K6OWGSHL/
    # So, just use native cmake find_package(PythonLibs) which
    # does the same thing
    echo 'find_package(PythonLibs REQUIRED)' > pymoab/cmake/FindPythonDev.cmake
    CXX=mpicxx codes_cmake \
        -D BUILD_SHARED_LIBS=ON \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D ENABLE_HDF5=ON \
        -D ENABLE_PYMOAB=ON \
        -D PYTHON_INCLUDE_DIR="$(codes_python_include_dir)"\
        -D PYTHON_LIBRARY="$(codes_python_lib_dir)"
    codes_make
    codes_make_install
    cd "$p"
}

openmc_openmc() {
    codes_download openmc-dev/openmc "$version"
    codes_cmake_fix_lib_dir
    CXX=mpicxx codes_cmake \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D ENABLE_PYMOAB=ON \
        -D HDF5_PREFER_PARALLEL=on \
        -D OPENMC_USE_DAGMC=on \
        -D OPENMC_USE_MPI=on
    codes_make
    codes_make_install
}

openmc_python_install() {
    cd openmc
    codes_python_install
    cd ../moab/build/pymoab
    codes_python_install
    install_pip_install openmc-data-downloader vtk
}

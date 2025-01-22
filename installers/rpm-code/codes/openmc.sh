#!/bin/bash

openmc_dagmc() {
    local p="$PWD"
    codes_download svalinn/DAGMC develop
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
    openmc_dagmc
    openmc_openmc
}

openmc_moab() {
    local p="$PWD"
    # 20230827 fixes pymoab/core.pyx:1509:48: no suitable method found
    codes_download https://bitbucket.org/fathomteam/moab.git bfccfc78e6cb3ddc02c39be437a64696bf126d86
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
    # Python 3.9 support was dropped a few commits after this. The
    # commits directly before 3.9 support being dropped all showed
    # broken builds. This was the first one to show a successful
    # build.
    codes_download openmc-dev/openmc b1b8a4c32834f82b0687600efbffa0e3181ef4c4
    codes_cmake_fix_lib_dir
    CXX=mpicxx codes_cmake \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
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
    install_pip_install \
        "neutronics_material_maker[density]" \
        dagmc_geometry_slice_plotter \
        openmc-data-downloader \
        git+https://github.com/svalinn/pydagmc.git \
        pymeshlab \
        vtk
}

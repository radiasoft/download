#!/bin/bash

fenics_python_install() {
    export BOOST_DIR=${codes_dir[prefix]}
    export PETSC_DIR=${codes_dir[prefix]}
    export SLEPC_DIR=${codes_dir[prefix]}
    local pybind11_version=2.2.4 #2.4.3
    # not setting, but was in dockerfile OPENBLAS_NUM_THREADS=1 OPENBLAS_VERBOSE=0
    install_pip_install pybind11=="$pybind11_version"
    codes_download https://github.com/pybind/pybind11/archive/v"$pybind11_version".tar.gz
    codes_cmake -DCMAKE_INSTALL_PREFIX="${codes_dir[pyenv_prefix]}" -DPYBIND11_TEST=False
    codes_make install
    cd ../..
    install_pip_install 'fenics>=2019.1.0,<2019.2.0'
    codes_download https://bitbucket.org/fenics-project/dolfin.git 2019.1.0.post0
    # Error is "Could not find DOLFIN pkg-config file"
    codes_cmake_fix_lib_dir
    codes_cmake -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make install
    cd ../python
    codes_python_install
    cd ../..
    codes_download https://bitbucket.org/fenics-project/mshr.git 2019.1.0
    codes_cmake -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make install
    cd ../python
    codes_python_install
    cd ../..
    unset BOOST_DIR PETSC_DIR SLEPC_DIR
}

fenics_main() {
    codes_yum_dependencies mpfr-devel gmp-devel
    codes_dependencies petsc4py slepc4py
}

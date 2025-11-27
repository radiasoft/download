#!/bin/bash

fenics_python_install() {
    cd dolfinx/python
    install_pip_install -r build-requirements.txt
    codes_python_install --check-build-dependencies --no-build-isolation
    unset BOOST_DIR PETSC_DIR SLEPC_DIR
}

fenics_main() {
    codes_yum_dependencies mpfr-devel gmp-devel spdlog-devel pugixml-devel
    codes_dependencies common slepc
    export BOOST_DIR=${codes_dir[prefix]} PETSC_DIR=${codes_dir[prefix]} SLEPC_DIR=${codes_dir[prefix]}
    install_pip_install fenics-basix fenics-ufl fenics-ffcx
    codes_download https://github.com/FEniCS/dolfinx.git v0.10.0 dolfinx 0.10.0
    cd cpp
    codes_cmake_fix_lib_dir
    codes_cmake2
    codes_cmake_build install
}

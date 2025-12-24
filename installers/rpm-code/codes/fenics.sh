#!/bin/bash

fenics_python_install() {
    cd dolfinx/python
    codes_python_install --check-build-dependencies --no-build-isolation
    unset BOOST_DIR PETSC_DIR SLEPC_DIR
}

fenics_main() {
    codes_yum_dependencies mpfr-devel gmp-devel spdlog-devel pugixml-devel
    codes_dependencies common slepc
    export BOOST_DIR=${codes_dir[prefix]} PETSC_DIR=${codes_dir[prefix]} SLEPC_DIR=${codes_dir[prefix]}
    install_pip_install fenics-basix==0.10.0 fenics-ufl==2025.2.0 fenics-ffcx==0.10.1.post0
    codes_download https://github.com/FEniCS/dolfinx.git v0.10.0 dolfinx 0.10.0
    cd cpp
    codes_cmake2
    codes_cmake_build install
}

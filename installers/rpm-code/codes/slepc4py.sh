#!/bin/bash

slepc4py_python_install() {
    NUM_CORES=$(codes_num_cores) SLEPC_DIR=${codes_dir[prefix]} \
        PETSC_DIR=${codes_dir[prefix]} \
        install_pip_install https://bitbucket.org/slepc/slepc4py/downloads/slepc4py-3.12.0.tar.gz
}


slepc4py_main() {
    codes_dependencies slepc petsc
}

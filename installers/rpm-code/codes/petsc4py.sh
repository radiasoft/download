#!/bin/bash

petsc4py_python_install() {
    NUM_CORES=$(codes_num_cores) PETSC_DIR=${codes_dir[prefix]} \
        install_pip_install https://bitbucket.org/petsc/petsc4py/downloads/petsc4py-3.12.0.tar.gz
}


petsc4py_main() {
    codes_dependencies petsc
}

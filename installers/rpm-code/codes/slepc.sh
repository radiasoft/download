#!/bin/bash

#slepc_python_install() {
#    NUM_CORES=$(codes_num_cores) SLEPC_DIR=${codes_dir[prefix]} \
#        install_pip_install https://bitbucket.org/slepc/slepc4py/downloads/slepc4py-3.12.0.tar.gz
#}


slepc_main() {
    codes_dependencies petsc
    local slepc_version=3.12.1
    codes_download https://gitlab.com/slepc/slepc/-/archive/v"$slepc_version/slepc-v$slepc_version".tar.gz
    # in slepc.rules there's a "include ${PETSC_DIR}/lib/petsc/conf/rules"
    export PETSC_DIR=${codes_dir[prefix]}
    ./configure --prefix="${codes_dir[prefix]}"
    codes_make
    codes_make_install
    unset PETSC_DIR
}

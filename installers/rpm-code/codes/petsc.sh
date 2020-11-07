#!/bin/bash

#petsc_python_install() {
#    NUM_CORES=$(codes_num_cores) PETSC_DIR=${codes_dir[prefix]} \
#        pip install https://bitbucket.org/petsc/petsc4py/downloads/petsc4py-3.12.0.tar.gz
#}


petsc_main() {
    codes_yum_dependencies eigen3-devel bison
    codes_dependencies common boost metis hypre
    local petsc_version=3.12.3
    codes_download https://gitlab.com/petsc/petsc/-/archive/v"$petsc_version/petsc-v$petsc_version".tar.gz
    ./configure --COPTFLAGS=-O2 --CXXOPTFLAGS=-O2 --FOPTFLAGS=-O2 \
        --with-fortran-bindings=no \
        --with-debugging=0 \
        --download-blacs \
        --download-mumps \
        --download-ptscotch \
        --download-scalapack \
        --download-spai \
        --download-suitesparse \
        --download-superlu \
        --prefix="${codes_dir[prefix]}"
    codes_make
    codes_make_install
}

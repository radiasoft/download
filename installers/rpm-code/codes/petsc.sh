#!/bin/bash

petsc_main() {
    codes_yum_dependencies eigen3-devel bison
    codes_dependencies common boost parmetis hypre
    codes_download https://gitlab.com/petsc/petsc.git release
    petsc_patch_spai
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
        --with-x=0 \
        --prefix="${codes_dir[prefix]}"
    codes_make
    codes_make_install
}

petsc_python_install() {
    cd petsc/src/binding/petsc4py
    PETSC_DIR="${codes_dir[prefix]}" codes_python_install
}

petsc_patch_spai() {
    perl -pi -e 's{(?<=CFLAGS = )}{-std=gnu99 }' config/BuildSystem/config/packages/spai.py
}

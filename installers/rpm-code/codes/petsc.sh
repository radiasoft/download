#!/bin/bash

petsc_main() {
    codes_yum_dependencies eigen3-devel bison
    codes_dependencies common boost parmetis hypre
    local petsc_version=3.17.4
    codes_download https://gitlab.com/petsc/petsc/-/archive/v"$petsc_version/petsc-v$petsc_version".tar.gz
    perl -pi -e 's{((?:FCFLAGS|OPTF)\s*=)}{$1 -fallow-argument-mismatch }' config/BuildSystem/config/packages/{scalapack,MUMPS}.py
    petsc_patch_configure
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
    cd src/binding/petsc4py
    PETSC_DIR="${codes_dir[prefix]}" codes_python_install
}

petsc_patch_configure() {
    cat > configure <<EOF
#!/usr/bin/env python3
import sys, os

sys.path.insert(0, os.path.abspath('config'))
import configure
configure.petsc_configure([])
EOF
}

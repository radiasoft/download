#!/bin/bash

slepc_main() {
    local slepc_version=3.17.2
    codes_download https://gitlab.com/slepc/slepc/-/archive/v"$slepc_version/slepc-v$slepc_version".tar.gz
    # in slepc.rules there's a "include ${PETSC_DIR}/lib/petsc/conf/rules"
    export PETSC_DIR=${codes_dir[prefix]} SLEPC_DIR="$PWD"
    slepc_patch_configure
    ./configure --prefix="${codes_dir[prefix]}"
    codes_make
    codes_make_install
    cd src/binding/slepc4py
    SLEPC_DIR=${codes_dir[prefix]} codes_python_install
    unset PETSC_DIR SLEPC_DIR
}

slepc_patch_configure() {
    cat > configure <<EOF
#!/usr/bin/env python3
import os

exec(open(os.path.join(os.path.dirname(__file__), 'config', 'configure.py')).read())
EOF
}

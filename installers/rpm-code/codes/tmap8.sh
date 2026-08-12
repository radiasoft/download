#!/bin/bash

tmap8_build() {
    PETSC_ARCH=arch-moose tmap8_update_and_rebuild petsc --with-shared-libraries=0
    tmap8_update_and_rebuild wasp
    tmap8_moose_python
    METHODS=opt tmap8_update_and_rebuild libmesh --disable-shared --enable-static --disable-netgen
    CPATH=$(codes_python_include_dir) METHOD=opt codes_make
    tmap8_install
}

tmap8_main() {
    codes_yum_dependencies bison flex libtirpc-devel
    codes_dependencies common
    declare tmp_d=$PWD/install
    mkdir "$tmp_d"
    codes_download idaholab/TMAP8 ec0413009094eb9efc8c06e5133cd3f63621e051
    declare d=$PWD/moose
    hit_so=$d/framework/contrib/hit/hit.so \
        LIBMESH_DIR=$tmp_d/tmap8/libmesh \
        MOOSE_DIR=$d \
        MOOOSE_JOBS=$(codes_num_cores) \
        PETSC_DIR=$tmp_d/petsc \
        PETSC_PREFIX=$tmp_d/petsc \
        WASP_DIR=$tmp_d/wasp \
        WASP_PREFIX=$tmp_d/wasp \
        tmap8_build
}

tmap8_install() {
    install -m 555 \
        "$PETSC_PREFIX"/lib/libceed.so \
        "$WASP_PREFIX"/lib/libwasp*.{so,so.*} \
        "$hit_so" \
        "${codes_dir[lib]}"
    install -m 555 tmap8-opt "${codes_dir[bin]}"/tmap8
}

tmap8_moose_python() {
    # build hit.so (Cython binding to the WASP HIT parser) needed by pyhit
    declare dest=
    CPATH=$(codes_python_include_dir) make -C "$(dirname "$hit_so")" -j"$(codes_num_cores)" bindings
    # `import hit` relies on LD_LIBRARY_PATH including
    # codes_dir[lib] to find the WASP libs it's linked against.
    chmod -R a+rX "$MOOSE_DIR"/python/ "$hit_so"
    cp -a "$MOOSE_DIR"/python/{moosetree,mooseutils,mms} "$hit_so" "$(codes_python_lib_dir)/"
    # avoids Failed to determine data file path for 'moose' & solid_mechanics
    install -d -m 755 "${codes_dir[share]}"/{solid_mechanics,moose}{,/data}
}

tmap8_update_and_rebuild() {
    declare which=$1
    shift
    "$MOOSE_DIR"/scripts/update_and_rebuild_$which.sh \
        --skip-submodule-update \
        "$@"
}

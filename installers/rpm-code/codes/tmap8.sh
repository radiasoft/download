#!/bin/bash

tmap8_main() {
    codes_yum_dependencies bison flex libtirpc-devel patchelf
    codes_dependencies common
    codes_download idaholab/TMAP8 ec0413009094eb9efc8c06e5133cd3f63621e051
    declare moose_dir=$PWD/moose
    declare petsc_prefix=${codes_dir[prefix]}/petsc
    declare libmesh_dir=${codes_dir[prefix]}/libmesh
    tmap8_petsc "$moose_dir" "$petsc_prefix"
    tmap8_wasp "$moose_dir"
    tmap8_moose_python "$moose_dir"
    tmap8_libmesh "$moose_dir" "$petsc_prefix" "$libmesh_dir"
    # python3-config --includes returns the virtualenv include dir whose headers are
    # symlinks; those symlinks are broken in the container RPM install. Point CPATH
    # at the base Python include dir (real files) so GCC always finds Python.h.
    declare python_inc
    python_inc=$(python3 -c 'import sysconfig; print(sysconfig.get_config_var("INCLUDEPY"))')
    CPATH=$python_inc \
    MOOSE_DIR=$moose_dir PETSC_DIR=$petsc_prefix LIBMESH_DIR=$libmesh_dir METHOD=opt \
        codes_make
    # Collect all MOOSE/TMAP8 shared libs from the build tree into a single
    # directory; petsc and libmesh are already installed to their own prefixes.
    declare lib_dir=${codes_dir[lib]}/tmap8
    mkdir -p "$lib_dir"
    find . \
        -not -path "*/petsc/*" \
        -not -path "*/libmesh/*" \
        -name "*.so*" \
        -exec cp --no-dereference --preserve=links {} "$lib_dir/" \;
    find "$lib_dir" -name "*.so*" ! -type l -exec strip --strip-unneeded {} \;
    # MOOSE and its modules look for data at <prefix>/share/<name>/data at runtime
    install -d -m 755 "${codes_dir[share]}/moose"
    cp -a "$moose_dir/framework/data" "${codes_dir[share]}/moose/"
    find "$moose_dir/modules" -maxdepth 2 -name data -type d | while read -r d; do
        declare mod
        mod=$(basename "$(dirname "$d")")
        install -d -m 755 "${codes_dir[share]}/$mod"
        cp -a "$d" "${codes_dir[share]}/$mod/"
    done
    strip --strip-unneeded tmap8-opt
    install -m 555 tmap8-opt "${codes_dir[bin]}/tmap8-bin"
    # Wrapper so the binary finds its libs regardless of the build tree
    declare lp="${lib_dir}:${codes_dir[prefix]}/libmesh/lib:${codes_dir[prefix]}/petsc/lib"
    install -m 555 /dev/stdin "${codes_dir[bin]}/tmap8" <<EOF
#!/bin/bash
export LD_LIBRARY_PATH="${lp}\${LD_LIBRARY_PATH:+:}\${LD_LIBRARY_PATH:-}"
exec "${codes_dir[bin]}/tmap8-bin" "\$@"
EOF
}

tmap8_moose_python() {
    declare moose_dir=$1
    declare hit_src=$moose_dir/framework/contrib/hit
    declare python_inc
    python_inc=$(python3 -c 'import sysconfig; print(sysconfig.get_config_var("INCLUDEPY"))')
    # build hit.so (Cython binding to the WASP HIT parser) needed by pyhit
    CPATH=$python_inc \
        make -C "$hit_src" -j"$(codes_num_cores)" bindings
    # rewrite build-tree RUNPATH to the installed WASP lib dir so pyhit
    # works without LD_LIBRARY_PATH after the RPM is deployed
    patchelf --set-rpath "${codes_dir[lib]}/tmap8" "$hit_src/hit.so"
    declare site
    site=$(codes_python_lib_dir)
    for pkg in pyhit moosetree mooseutils mms; do
        cp -r "$moose_dir/python/$pkg" "$site/"
    done
    # hit.so must be importable as a top-level module (pyhit does `import hit`)
    install -m 755 "$hit_src/hit.so" "$site/"
}

tmap8_wasp() {
    declare moose_dir=$1
    MOOSE_DIR=$moose_dir \
    MOOSE_JOBS=$(codes_num_cores) \
        "$moose_dir"/scripts/update_and_rebuild_wasp.sh \
        --skip-submodule-update
}

tmap8_libmesh() {
    declare moose_dir=$1 petsc_prefix=$2 libmesh_dir=$3
    MOOSE_DIR=$moose_dir \
    PETSC_DIR=$petsc_prefix \
    LIBMESH_DIR=$libmesh_dir \
    METHODS=opt \
    MOOSE_JOBS=$(codes_num_cores) \
        "$moose_dir"/scripts/update_and_rebuild_libmesh.sh \
        --skip-submodule-update
}

tmap8_petsc() {
    declare moose_dir=$1 petsc_prefix=$2
    MOOSE_DIR=$moose_dir \
    PETSC_DIR=$moose_dir/petsc \
    PETSC_ARCH=arch-moose \
    PETSC_PREFIX=$petsc_prefix \
    MOOSE_JOBS=$(codes_num_cores) \
        "$moose_dir"/scripts/update_and_rebuild_petsc.sh \
        --skip-submodule-update
}

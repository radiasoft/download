#!/bin/bash

tmap8_main() {
    codes_yum_dependencies bison flex libtirpc-devel
    codes_dependencies common
    codes_download idaholab/TMAP8 ec0413009094eb9efc8c06e5133cd3f63621e051
    declare moose_dir=$PWD/moose
    declare petsc_prefix=${codes_dir[prefix]}/tmap8/petsc
    declare libmesh_dir=${codes_dir[prefix]}/tmap8/libmesh
    tmap8_petsc "$moose_dir" "$petsc_prefix"
    tmap8_wasp "$moose_dir"
    tmap8_moose_python "$moose_dir"
    tmap8_libmesh "$moose_dir" "$petsc_prefix" "$libmesh_dir"
    # libmesh installs bin/ utility programs (meshtool, splitter, compare, etc.),
    # examples/, contrib/, share/, and etc/ that TMAP8 never uses; with static
    # PETSc/libmesh each utility separately embeds the full dependency tree
    # (~400MB apiece). Nothing under libmesh_dir is needed at tmap8 runtime (it's
    # fully statically linked), so keep only lib/ and include/ (needed below to
    # compile/link TMAP8), plus two files moose/framework/build.mk shells out to
    # while compiling TMAP8 itself: bin/libmesh-config (compiler/link flags) and
    # contrib/bin/libtool (drives libtool-mode compilation of MOOSE's own .lo
    # objects; build.mk checks this path before falling back to a top-level
    # LIBMESH_DIR/libtool that libmesh's "make install" never actually creates).
    # Verified against build.mk that no other LIBMESH_DIR paths are referenced.
    find "$libmesh_dir" -mindepth 1 -maxdepth 1 -not -name lib -not -name include \
        -not -name bin -not -name contrib -exec rm -rf {} +
    find "$libmesh_dir/bin" -mindepth 1 -not -name libmesh-config -delete
    find "$libmesh_dir/contrib" -mindepth 1 -not -path "*/contrib/bin" -not -name libtool -delete
    # Static .a archives carry full debug/symbol info that shared libs would have
    # dropped at link time; stripping is safe since only the global symbol table
    # (needed for later linking) survives, not the archive index itself.
    find "$petsc_prefix/lib" "$libmesh_dir/lib" -name "*.a" -exec strip --strip-unneeded {} \;
    # Tutorial/example source trees, standalone PTScotch CLI tools, and other
    # dev-only PETSc share/ content are not used by TMAP8 at build or run time.
    rm -rf "$petsc_prefix/share/petsc/examples" "$petsc_prefix/share/petsc/datafiles" \
        "$petsc_prefix/share/petsc/matlab" "$petsc_prefix/share/petsc/saws" \
        "$petsc_prefix/share/petsc/xml" "$petsc_prefix/share/petsc/suppressions" \
        "$petsc_prefix/share/slepc/examples" "$petsc_prefix/share/slepc/datafiles" \
        "$petsc_prefix/share/man" "$petsc_prefix/bin"
    # python3-config --includes returns the virtualenv include dir whose headers are
    # symlinks; those symlinks are broken in the container RPM install. Point CPATH
    # at the base Python include dir (real files) so GCC always finds Python.h.
    # codes_python_include_dir gives the same base path (verified: unlike
    # python3-config, distutils.sysconfig.get_python_inc() isn't venv-relative).
    CPATH=$(codes_python_include_dir) \
    MOOSE_DIR=$moose_dir PETSC_DIR=$petsc_prefix LIBMESH_DIR=$libmesh_dir METHOD=opt \
        codes_make
    # Headers/archives are only needed to compile/link against petsc; nothing in
    # the installed RPM (or at tmap8/moose-python runtime) needs them once
    # tmap8-opt is linked. In fact nothing under petsc_prefix is needed at
    # runtime except lib/libceed.so (verified empirically: tmap8 runs identically
    # with everything else removed): libCEED's own build never produces a static
    # libceed.a (see tmap8_petsc's --with-shared-libraries=0 comment), so it's
    # the one piece PETSc ends up linking dynamically instead of embedding like
    # everything else. Neither moose's python tools (pyhit/mooseutils/mms) nor
    # tmap8-opt reference any other petsc_prefix path.
    find "$petsc_prefix" -mindepth 1 -maxdepth 1 -not -name lib -exec rm -rf {} +
    find "$petsc_prefix/lib" -mindepth 1 -not -name libceed.so -delete
    # libmesh is fully statically linked with no runtime data of its own (verified
    # empirically: tmap8 runs identically with libmesh_dir removed entirely), so
    # nothing under it is needed once tmap8-opt is linked.
    rm -rf "$libmesh_dir"
    # Collect all MOOSE/TMAP8 shared libs from the build tree into codes_dir[lib]
    # directly (flat, like libopenmc.so does), rather than a tmap8-only
    # subdirectory; petsc and libmesh are already installed to their own
    # prefixes.
    declare lib_dir=${codes_dir[lib]}
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
    install_file_from_stdin 555 vagrant vagrant "${codes_dir[bin]}/tmap8" <<EOF
#!/bin/bash
export LD_LIBRARY_PATH="$lib_dir:$petsc_prefix/lib\${LD_LIBRARY_PATH:+:}\${LD_LIBRARY_PATH:-}"
exec "${codes_dir[bin]}/tmap8-bin" "\$@"
EOF
}

tmap8_moose_python() {
    declare moose_dir=$1
    declare hit_src=$moose_dir/framework/contrib/hit
    # build hit.so (Cython binding to the WASP HIT parser) needed by pyhit
    CPATH=$(codes_python_include_dir) \
        make -C "$hit_src" -j"$(codes_num_cores)" bindings
    # `import hit` (pyhit does this) relies on LD_LIBRARY_PATH including
    # codes_dir[lib] to find the WASP libs it's linked against.
    for pkg in pyhit moosetree mooseutils mms; do
        cp -r "$moose_dir/python/$pkg" "$(codes_python_lib_dir)/"
    done
    # hit.so must be importable as a top-level module (pyhit does `import hit`)
    install -m 555 "$hit_src/hit.so" "$(codes_python_lib_dir)/"
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
        --skip-submodule-update \
        --disable-shared \
        --enable-static \
        --disable-netgen
}

tmap8_petsc() {
    declare moose_dir=$1 petsc_prefix=$2
    MOOSE_DIR=$moose_dir \
    PETSC_DIR=$moose_dir/petsc \
    PETSC_ARCH=arch-moose \
    PETSC_PREFIX=$petsc_prefix \
    MOOSE_JOBS=$(codes_num_cores) \
        "$moose_dir"/scripts/update_and_rebuild_petsc.sh \
        --skip-submodule-update \
        --with-shared-libraries=0
}

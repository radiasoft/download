#!/bin/bash
set -euo pipefail

flash_tarball_main() {
    local d=$PWD/proprietary
    local t=$d/FLASH-4.6.2.tar.gz
    if [[ ! -f $t ]]; then
            install_err "$t must exist"
    fi
    install_tmp_dir
    local p=$PWD
    local r=()
    install_url radiasoft/download installers
    install_script_eval rpm-code/codes.sh
    codes_download rsflash
    git fetch --unshallow
    local x
    for x in \
        'CapLaser3D 47a641aa467ff48c1337a69e6c3a6778e5b854ae' \
        'CapLaserBELLA master' \
    ; do
        x=( $x )
        git checkout --quiet "${x[1]}"
        cd "config/${x[0]}"
        # POSIT: Matches sirepo.sim_data._flash_problem_files_archive_basename
        n=problemFiles-archive.${x[0]}.zip
        zip --quiet "$p/$n" *F90 Config Makefile
        r+=($n)
        cd ../..
    done
    cd ..
    r+=( "$(flash_tarball_patch_and_update_tgz "$t")" )
    x=$d/flash-$(date -u +%Y%m%d.%H%M%S).tar.gz
    rm -f "$x"
    tar czf "$x" "${r[@]}"
    ln -s --force "$(basename "$x")" $d/flash-dev.tar.gz
}

flash_tarball_patch_and_update_tgz() {
    local src_tgz=$1
    local b="$(basename "$src_tgz" .tar.gz)"
    tar xzf "$src_tgz"
    cd "$b"
    local d=$(dirname "$BIVIO_MPI_LIB")
    patch --quiet sites/Prototypes/Linux/Makefile.h <<EOF
6c6
< MPI_PATH   = /usr/local/mpich2/
---
> MPI_PATH   = $d/
8,9c8,9
< HDF5_PATH  = /usr/local/hdf5
< HYPRE_PATH = /usr/local/hypre
---
> HDF5_PATH  = $d/
> HYPRE_PATH = $HOME/.local
70c70
< F90FLAGS =
---
> F90FLAGS = -fallow-argument-mismatch
EOF
    cd ..
    mv "$b" "flash"
    # POSIT: Matches sirepo.sim_data.flash._flash_src_tarball_basename
    local r=source.tar.gz
    tar czf "$r" flash
    echo "$r"
}

#!/bin/bash
set -euo pipefail

_flash_tarball_version=4.6.2

flash_tarball_main() {
    local d=$PWD/proprietary
    local t=$d/FLASH-$_flash_tarball_version.tar.gz
    if [[ ! -f $t ]]; then
            install_err "$t must exist"
    fi
    install_tmp_dir
    local p=$PWD
    local r=()
    install_url radiasoft/download installers
    install_script_eval rpm-code/codes.sh
    r="$(flash_untar $t)"
    flash_patch "$r"
    flash_add_examples "$r"
    o=flash.tar.gz
    tar czf "$o" "$r"
    x=$d/flash-$(date -u +%Y%m%d.%H%M%S).tar.gz
    rm -f "$x"
    tar czf "$x" "$o"
    ln -s --force "$(basename "$x")" $d/flash-dev.tar.gz
}

flash_add_examples() {
    local flash_dir="$1"
    codes_download flashcap
    git fetch --unshallow
    local x
    for x in \
        'CapLaser3D bella_3dSetup.par' \
        'CapLaserBELLA bella.par' \
    ; do
        x=( $x )
        local i="config/${x[0]}"
        # POSIT: sirepo.sim_data.flash.FLASH_PAR_FILE
        cp "$i/${x[1]}" "$i/flash.par"
        cp -R "$i"  "../$flash_dir/source/Simulation/SimulationMain/"
    done
    cd ..

}

flash_patch() {
    cd "$1"
    # POSIT: Fedora using mpich
    local d=/usr/lib64/mpich
    patch --quiet sites/Prototypes/Linux/Makefile.h <<EOF
6c6
< MPI_PATH   = /usr/local/mpich2/
---
> MPI_PATH   = $d/
8,9c8,9
< HDF5_PATH  = /usr/local/hdf5
< HYPRE_PATH = /usr/local/hypre
---
> HDF5_PATH  = $d
> HYPRE_PATH = /home/vagrant/.local
70c70
< F90FLAGS =
---
> F90FLAGS = -fallow-argument-mismatch
EOF
    cd ..
}

flash_untar() {
    local src_tgz=$1
    # missing the dash
    local b=FLASH$_flash_tarball_version
    tar xzf "$src_tgz"
    # POSIT: Matches sirepo.sim_data.flash._flash_src_tarball_basename
    local r='flash'
    mv "$b" "$r"
    echo "$r"
}

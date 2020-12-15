#!/bin/bash
#
# To run: curl radia.run | bash -s flash-tarball
#
set -euo pipefail

flash_main() {
    local d="$PWD"
    if [[ ! -f "$d/FLASH-4.6.2.tar.gz" ]]; then
        install_err "$d/FLASH-4.6.2.tar.gz must exist"
    fi
    cd ~/src/radiasoft/rsflash
    git checkout --quiet master
    git clean --quiet --force -d
    git pull --quiet
    local r=()
    for x in \
        "CapLaser3D 47a641aa467ff48c1337a69e6c3a6778e5b854ae" \
        "CapLaserBELLA master" \
    ; do
        local x=( $x )
        git checkout --quiet "${x[1]}"
        cd "config/${x[0]}"
        # POSIT: Matches sirepo.sim_data._flash_problem_files_archive_basename
        n="problemFiles-archive.${x[0]}.zip"
        zip --quiet "$d/$n" {*F90,Config,Makefile}
        r+=($n)
        cd ../..
    done
    cd "$d"
    r+=("$(flash_patch_makefile)")
    tar czf flash.tar.gz "${r[@]}"
    rm -rf "${r[@]}"
    # TODO(e-carlin):  what about outside of dev do we put it in $p?
    local p="$HOME/src/radiasoft/rsconf/proprietary/"
    if [[ ! -d $p ]]; then
        echo 'you need to setup rsconf:

cd ~/src/radiasoft
gcl rsconf
cd rsconf
pip install -e . | cat
rsconf build
'
        exit 1
    fi
    mv flash.tar.gz "$p/flash-$install_channel.tar.gz"
}

flash_patch_makefile() {
    local b='FLASH-4.6.2'
    tar xzf "$b.tar.gz"
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
    local r='source.tar.gz'
    tar czf "$r" "flash"
    rm -rf "flash"
    echo "$r"
}

flash_main

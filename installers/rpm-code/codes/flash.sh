#!/bin/bash

flash_main() {
    codes_dependencies hypre
    codes_download_proprietary "flash/FLASH-4.6.2.tar.gz" "FLASH4.6.2"
    flash_patch_makefile
    install -d 755 "${codes_dir[share]}"/flash4
    for n in CapLaserBELLA RTFlame
    do
        flash_make_and_install_type $n
    done
}

flash_make_and_install_type() {
    "flash_setup_$n" "$n"
    cd "$1"
    codes_make
    # POSIT: Sirepo assumes the exe is named flash4-flashType
    install -m 755 flash4 "${codes_dir[bin]}"/flash4-"$1"
    # POSIT: Sirepo assumes the setup_units file is named setup_units-flashType
    install -m 444 setup_units "${codes_dir[share]}"/flash4/setup_units-"$1"
    cd ..
}

flash_patch_makefile() {
    local d=$(dirname "$BIVIO_MPI_LIB")
    patch sites/Prototypes/Linux/Makefile.h <<EOF
6c6
< MPI_PATH   = /usr/local/mpich2/
---
> MPI_PATH   = $d/
8,9c8,9
< HDF5_PATH  = /usr/local/hdf5
< HYPRE_PATH = /usr/local/hypre
---
> HDF5_PATH  = $d/
> HYPRE_PATH = ${codes_dir[prefix]}
EOF
}

flash_setup_CapLaserBELLA() {
    codes_download_proprietary "flash/$1-4.6.2.tar.gz" "source"
    cd ..
    ./setup "$1" -objdir="$1" -auto -2d -nxb=16 -nyb=16 +hdf5typeio \
            species=fill,wall +mtmmmt +usm3t +mgd mgd_meshgroups=6 \
            -parfile=caplaser_basic.par +laser \ ed_maxPulses=1
            ed_maxPulseSections=4 ed_maxBeams=1

}

flash_setup_RTFlame() {
    ./setup "$1" -objdir="$1" -2d -auto -nxb=16 -nyb=16
}

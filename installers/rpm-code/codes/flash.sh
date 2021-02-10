#!/bin/bash

flash_main() {
    local f="FLASH-4.6.2"
    codes_dependencies hypre
    codes_download_proprietary "flash/$f.tar.gz" "$f"
    flash_patch_makefile
    local n
    for n in CapLaser3D CapLaserBELLA; do
        flash_download_simulation_source "$n"
    done
    cd ..
    mv "$f" "flash"
    local a="flash.tar.gz"
    tar --create  --gzip --file "$a" flash
    install -d 755 "${codes_dir[share]}"/flash
    install -m 444 "$a" "${codes_dir[share]}"/flash
}

flash_download_simulation_source() {
    codes_download_proprietary "flash/$1-4.6.2.tar.gz" "source"
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
70c70
< F90FLAGS =
---
> F90FLAGS = -fallow-argument-mismatch
EOF
}

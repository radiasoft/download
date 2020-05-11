#!/bin/bash

flash_main() {
    codes_dependencies hypre
    codes_download_proprietary "flash/FLASH-4.6.2.tar.gz" "FLASH4.6.2"
    local flash_src_root=$PWD
    patch_makefile
    for n in CapLaser RTFlame
    do
        setup_$n $n
        make_and_install $n
    done
}

make_and_install() {
    cd $1
    codes_make
    install -m 755 flash4 "${codes_dir[bin]}"/flash4-$1
    install -d 755 "${codes_dir[share]}"/flash4
    install -m 444 setup_units "${codes_dir[share]}"/flash4/setup_units-$1
    cd ..
}

patch_makefile() {
    patch sites/Prototypes/Linux/Makefile.h <<'EOF'
6c6
< MPI_PATH   = /usr/local/mpich2/
---
> MPI_PATH   = /usr/lib64/mpich/
8,9c8,9
< HDF5_PATH  = /usr/local/hdf5
< HYPRE_PATH = /usr/local/hypre
---
> HDF5_PATH  = /usr/lib64/mpich
> HYPRE_PATH = /home/vagrant/.local
157c157
< #----------------------------------------------------------------------------
---
> #----------------------------------------------------------------------------
EOF
}

setup_CapLaser() {
    cd source/Simulation/SimulationMain/magnetoHD
    codes_download_proprietary "flash/CapLaserBELLA-4.6.2.tar.gz" "CapLaserBELLA"
    cd $flash_src_root
    ./setup -auto magnetoHD/CapLaser -2d -nxb=16 -nyb=16 +hdf5typeio \
            species=fill,wall +mtmmmt +usm3t +mgd mgd_meshgroups=6 \
            -parfile=caplaser_basic.par -objdir=$1 +laser \
            ed_maxPulses=1 ed_maxPulseSections=4 ed_maxBeams=1

}

setup_RTFlame() {
    ./setup RTFlame -2d -auto -nxb=16 -nyb=16 -objdir=$1
}

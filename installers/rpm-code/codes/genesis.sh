#!/bin/bash
genesis_main() {
    codes_dependencies common
    codes_download https://github.com/slaclab/Genesis-1.3-Version2.git
    codes_cmake -D USE_MPI=OFF
    codes_make all
    install -m 555 genesis2 "${codes_dir[bin]}"/genesis
    cd ..
    rm -rf build
    codes_cmake -D USE_MPI=ON
    codes_make all
    install -m 555 genesis2-mpi "${codes_dir[bin]}"/genesis_mpi
    ln -s genesis "${codes_dir[bin]}"/genesis2
    ln -s genesis_mpi "${codes_dir[bin]}"/genesis2-mpi
}

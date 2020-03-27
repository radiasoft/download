#!/bin/bash
genesis_main() {
    codes_dependencies common
    codes_download_foss genesis-2.0-120629.tar.gz
    # no parallel make
    make
    make multi
    make EXECUTABLE=genesis_mpi COMPILER=mpif77
    install -m 555 genesis genesis_mpi "${codes_dir[bin]}"
}

#!/bin/bash
codes_dependencies common
codes_download http://genesis.web.psi.ch/download/source/genesis_source_2.0_120629.tar.gz Genesis_Current
make
make multi
make EXECUTABLE=genesis_mpi COMPILER=mpif77
install -m 555 genesis genesis_mpi "${codes_dir[bin]}"

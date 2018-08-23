#!/bin/bash
codes_dependencies common
codes_download_foss genesis-3.2.1-beta.tar.gz Develop/source
make 'LIB=-lgfortran -lstdc++ -lhdf5 -L/usr/lib64 -L/usr/lib64/openmpi/lib' 'CCOMPILER=mpicxx'
install -m 555 genesis "$codes_bin_dir"

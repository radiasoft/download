#!/bin/bash
base_pwd=$PWD
# original source has bad ssl cert:
# https://amas.psi.ch/H5hut/raw-attachment/wiki/DownloadSources/H5hut-1.99.13.tar.gz
# Doc: https://amas.psi.ch/H5hut/wiki/H5hutInstall
codes_download_foss H5hut-1.99.13.tar.gz
patch -p0 < "$codes_data_src_dir"/opal/H5hut-1.99.13.patch
./autogen.sh
CC=mpicc CXX=mpicxx ./configure \
  --enable-parallel \
  --prefix="$(pyenv prefix)" \
  --with-pic \
  --enable-shared
make install
cd "$base_pwd"

#codes_download https://gitlab.psi.ch/OPAL/src.git OPAL-1.6
# The git repo is 1.6G, and takes a long time to load. The tgz is 3M
codes_download_foss codes_download_foss OPAL-1.6-20171009.041421.tar.gz
mkdir build
cd build
CMAKE_PREFIX_PATH="$(pyenv prefix)" H5HUT_PREFIX="$(pyenv prefix)" \
    HDF5_INCLUDE_DIR=/usr/include \
    HDF5_LIBRARY_DIR=/usr/lib64/openmpi/lib \
    CC=mpicc CXX=mpicxx \
    cmake \
    --prefix="$(pyenv prefix)" \
    -DCMAKE_INSTALL_PREFIX="$(pyenv prefix)" \
    -DENABLE_SAAMG_SOLVER=TRUE \
    ..
make -j 2 install
cd "$base_pwd"

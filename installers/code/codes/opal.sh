#!/bin/bash
base_pwd=$PWD
# original source has bad ssl cert:
# https://amas.psi.ch/H5hut/raw-attachment/wiki/DownloadSources/H5hut-1.99.13.tar.gz
# Doc: https://amas.psi.ch/H5hut/wiki/H5hutInstall
codes_download_foss H5hut-1.99.13.tar.gz
patch -p0 < "$codes_data_src_dir"/opal/H5hut-1.99.13.patch
perl -pi -e 's{\`which}{\`type -p}' autogen.sh
./autogen.sh
perl -pi -e 's{\`which}{\`type -p}' configure
CC=mpicc CXX=mpicxx ./configure \
  --enable-parallel \
  --prefix="$(pyenv prefix)" \
  --with-pic \
  --enable-shared
# Cannot run in parallel, bad dependencies
make install
cd "$base_pwd"

# /home/vagrant/src/radiasoft/codes/opal-20171212.221025/OPAL-1.9-20171123.105913/opt-pilot/Expression/Parser/expression_def.hpp:178:50:   required from ‘client::parser::expression<Iterator>::expression(client::error_handler<Iterator>&) [with Iterator = __gnu_cxx::__normal_iterator<const char*, std::__cxx11::basic_string<char> >]’
# /home/vagrant/src/radiasoft/codes/opal-20171212.221025/OPAL-1.9-20171123.105913/opt-pilot/Expression/Parser/expression.cpp:10:33:   required from here
# /usr/include/boost/phoenix/function/detail/cpp03/preprocessed/function_operator_10.hpp:57:# 76: error: invalid conversion from ‘const char*’ to ‘param_type {aka char*}’ [-fpermissive]
#              return detail::expression::function_eval<F, A0 , A1 , A2>::make(f, a0 , a1 , a2);

#codes_download https://gitlab.psi.ch/OPAL/src.git OPAL-1.9
# The git repo is 1.6G, and takes a long time to load. The tgz is 3M
# Last known working version of OPAL
codes_download_foss OPAL-1.9-20180206.090701.tar.gz
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
codes_make_install
cd "$base_pwd"

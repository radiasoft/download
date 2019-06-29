#!/bin/bash
codes_dependencies trilinos H5hut

# /home/vagrant/src/radiasoft/codes/opal-20171212.221025/OPAL-1.9-20171123.105913/opt-pilot/Expression/Parser/expression_def.hpp:178:50:   required from ‘client::parser::expression<Iterator>::expression(client::error_handler<Iterator>&) [with Iterator = __gnu_cxx::__normal_iterator<const char*, std::__cxx11::basic_string<char> >]’
# /home/vagrant/src/radiasoft/codes/opal-20171212.221025/OPAL-1.9-20171123.105913/opt-pilot/Expression/Parser/expression.cpp:10:33:   required from here
# /usr/include/boost/phoenix/function/detail/cpp03/preprocessed/function_operator_10.hpp:57:# 76: error: invalid conversion from ‘const char*’ to ‘param_type {aka char*}’ [-fpermissive]
#              return detail::expression::function_eval<F, A0 , A1 , A2>::make(f, a0 , a1 , a2);

#codes_download https://gitlab.psi.ch/OPAL/src.git OPAL-1.9
# The git repo is 1.6G, and takes a long time to load. The tgz is 3M
# Last known working version of OPAL
codes_download_foss OPAL-2.0.1.tar.xz
CMAKE_PREFIX_PATH="${codes_dir[prefix]}" H5HUT_PREFIX="${codes_dir[prefix]}" \
    HDF5_INCLUDE_DIR=/usr/include \
    HDF5_LIBRARY_DIR="$BIVIO_MPI_PREFIX"/lib \
    CC=mpicc CXX=mpicxx \
    codes_cmake \
    --prefix="${codes_dir[prefix]}" \
    -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
    -DENABLE_SAAMG_SOLVER=TRUE
codes_make_install

#!/bin/bash
codes_dependencies trilinos H5hut pyOPALTools

# /home/vagrant/src/radiasoft/codes/opal-20171212.221025/OPAL-1.9-20171123.105913/opt-pilot/Expression/Parser/expression_def.hpp:178:50:   required from ‘client::parser::expression<Iterator>::expression(client::error_handler<Iterator>&) [with Iterator = __gnu_cxx::__normal_iterator<const char*, std::__cxx11::basic_string<char> >]’
# /home/vagrant/src/radiasoft/codes/opal-20171212.221025/OPAL-1.9-20171123.105913/opt-pilot/Expression/Parser/expression.cpp:10:33:   required from here
# /usr/include/boost/phoenix/function/detail/cpp03/preprocessed/function_operator_10.hpp:57:# 76: error: invalid conversion from ‘const char*’ to ‘param_type {aka char*}’ [-fpermissive]
#              return detail::expression::function_eval<F, A0 , A1 , A2>::make(f, a0 , a1 , a2);

#codes_download https://gitlab.psi.ch/OPAL/src.git OPAL-1.9
# The git repo is 1.6G, and takes a long time to load. The tgz is 3M
# Last known working version of OPAL
codes_download_foss OPAL-1.9-20180206.090701.tar.gz
CMAKE_PREFIX_PATH="$(pyenv prefix)" H5HUT_PREFIX="$(pyenv prefix)" \
    HDF5_INCLUDE_DIR=/usr/include \
    HDF5_LIBRARY_DIR=/usr/lib64/openmpi/lib \
    CC=mpicc CXX=mpicxx \
    codes_cmake \
    --prefix="$(pyenv prefix)" \
    -DCMAKE_INSTALL_PREFIX="$(pyenv prefix)" \
    -DENABLE_SAAMG_SOLVER=TRUE
# Need to add -lsz, and this was the easiest way...
# /usr/bin/ld: /usr/lib64/openmpi/lib/libhdf5.a(H5Zszip.o): undefined reference to symbol 'SZ_BufftoBuffDecompress'
# /usr/lib64/libsz.so.2: error adding symbols: DSO missing from command line
perl -pi -e 's/-lquadmath/$& -lsz/' src/CMakeFiles/opal.dir/link.txt
codes_make_install

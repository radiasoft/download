#!/bin/bash
codes_yum_dependencies blas-devel
codes_dependencies trilinos H5hut boost
codes_download https://gitlab.psi.ch/OPAL/src/-/archive/OPAL-2.2.0/src-OPAL-2.2.0.tar.gz
# https://stackoverflow.com/a/20991533
# boost is compiled multithreaded, because it doesn't mean "pthreads",
# but just that the code takes a bit more care on values in static sections.
# If we don't turn this ON, it will not find the variant compiled.
perl -pi -e 's{(?<=Boost_USE_MULTITHREADED )OFF}{ON}' CMakeLists.txt
CMAKE_PREFIX_PATH="${codes_dir[prefix]}" \
    H5HUT_PREFIX="${codes_dir[prefix]}" \
    BOOST_DIR="${codes_dir[prefix]}" \
    HDF5_INCLUDE_DIR=/usr/include \
    HDF5_LIBRARY_DIR="$BIVIO_MPI_LIB" \
    CC=mpicc CXX=mpicxx \
    codes_cmake \
    --prefix="${codes_dir[prefix]}" \
    -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
    -DENABLE_SAAMG_SOLVER=TRUE
ls -ald /home/vagrant/.local/lib/cmake
codes_make_install

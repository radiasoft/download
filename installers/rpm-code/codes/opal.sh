#!/bin/bash
opal_main() {
    codes_dependencies trilinos h5hut boost
    codes_download https://gitlab.psi.ch/OPAL/src/-/archive/OPAL-2.4.0/src-OPAL-2.4.0.tar.bz2
    perl -pi -e '
        # https://stackoverflow.com/a/20991533
        # boost is compiled multithreaded, because it does not mean "pthreads",
        # but just that the code takes a bit more care on values in static sections.
        # If we do not turn this ON, it will not find the variant compiled.
        s{(?<=Boost_USE_MULTITHREADED )OFF}{ON};
        # otherwise fails with -lmpi_mpifh not found, because
        # that is part of openmpi, not mpich
        s{.*mpi_mpifh.*}{};
        s{-fPIE}{};
        s{add_link_options.*-pie.*}{};
    ' CMakeLists.txt
    # need to specify CC and CXX otherwise build uses wrong
    # compiler.
    H5HUT_PREFIX="${codes_dir[prefix]}" \
        BOOST_DIR="${codes_dir[prefix]}" \
        HDF5_INCLUDE_DIR=/usr/include \
        HDF5_LIBRARY_DIR="$BIVIO_MPI_LIB" \
        CC=mpicc CXX=mpicxx \
        codes_cmake \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D ENABLE_SAAMG_SOLVER=TRUE \
        -D CMAKE_POSITION_INDEPENDENT_CODE=FALSE \
        -D USE_STATIC_LIBRARIES=FALSE
    codes_make all
    # We need to strip because the binary is very large
    # https://github.com/radiasoft/download/issues/140
    install -m 755 --strip src/opal "${codes_dir[bin]}"/opal
}

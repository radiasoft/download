#!/bin/bash
opal_main() {
    codes_dependencies trilinos h5hut boost
    opal_mithra
    codes_download https://gitlab.psi.ch/OPAL/src/-/archive/OPAL-2021.1.0/src-OPAL-2021.1.0.tar.bz2
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
	MITHRA_INCLUDE_DIR="${codes_dir[include]}" \
	MITHRA_LIBRARY_DIR="${codes_dir[lib]}" \
        CC=mpicc CXX=mpicxx \
        codes_cmake \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
	-D ENABLE_OPAL_FEL=yes \
        -D ENABLE_SAAMG_SOLVER=TRUE \
        -D CMAKE_POSITION_INDEPENDENT_CODE=FALSE \
        -D USE_STATIC_LIBRARIES=FALSE
    codes_make all
    # We need to strip because the binary is very large
    # https://github.com/radiasoft/download/issues/140
    install -m 755 --strip src/opal "${codes_dir[bin]}"/opal
}

opal_mithra() {
    codes_download https://github.com/aryafallahi/mithra/archive/2.0.tar.gz mithra-2.0 mithra 2.0
    # makefile handwritten without appropriate dependencies
    CFLAGS='-fPIC' make install
    mkdir "${codes_dir[include]}/mithra"
    install -m 644 ./include/mithra/* "${codes_dir[include]}/mithra"
    install -m 644 './lib/libmithra.a' "${codes_dir[lib]}"
    cd ..
}

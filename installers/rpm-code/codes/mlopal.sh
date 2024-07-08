#!/bin/bash
mlopal_main() {
    codes_dependencies common opal trilinos
    codes_download https://github.com/radiasoft/mlopal.git
    # Copied from opal
    # git.radiasoft.org/download/issues/342
    perl -pi -e 's{add_compile_options \(-Werror\)}{}' CMakeLists.txt
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
    install -m 755 --strip src/opal "${codes_dir[bin]}"/mlopal
    mlopal_script
}

mlopal_script() {
    declare c=rs_mlopal
    codes_download_module_file "$c.sh"
    RS_MLOPAL_FOSS_SERVER=$(install_foss_server) \
    perl -p -e 's/\$\{(\w+)\}/$ENV{$1} || die("$1: not found")/eg' "$c.sh" \
        | install -m 555 /dev/stdin "${codes_dir[bin]}"/"$c"
}

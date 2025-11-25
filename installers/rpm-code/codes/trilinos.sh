#!/bin/bash

trilinos_main() {
    codes_dependencies parmetis
    codes_download https://github.com/trilinos/Trilinos/archive/refs/tags/trilinos-release-16-1-0.tar.gz Trilinos-trilinos-release-16-1-0 trilinos 16.1.0
    # faster for testing
    # codes_download_foss trilinos-release-16-1-0.tar.gz Trilinos-trilinos-release-16-1-0 trilinos 16.1.0
    local x=(
        -D CMAKE_CXX_FLAGS:STRING="-DMPICH_IGNORE_CXX_SEEK -fPIC"
        -D CMAKE_CXX_STANDARD:STRING="17"
        -D CMAKE_C_FLAGS:STRING="-DMPICH_IGNORE_CXX_SEEK -fPIC"
        -D CMAKE_Fortran_FLAGS:STRING="-fPIC"
        -D CMAKE_INSTALL_PREFIX:PATH="${codes_dir[prefix]}"
        -D METIS_LIBRARY_DIRS="${codes_dir[lib]}"
        -D MPI_BASE_DIR="$(dirname "$BIVIO_MPI_LIB")"
        -D MPI_CXX_COMPILER:FILEPATH=mpicxx
        -D MPI_C_COMPILER:FILEPATH=mpicc
        -D MPI_Fortran_COMPILER:FILEPATH=mpif77
        -D TPL_ENABLE_BLAS:BOOL=ON
        -D TPL_ENABLE_DLlib:BOOL=OFF
        -D TPL_ENABLE_LAPACK:BOOL=ON
        -D TPL_ENABLE_METIS:BOOL=ON
        -D TPL_ENABLE_MPI=ON
        -D TPL_ENABLE_ParMETIS:BOOL=ON
        -D TPL_ENABLE_QT:BOOL=OFF
        -D Trilinos_ENABLE_Amesos2:BOOL=ON
        -D Trilinos_ENABLE_Amesos:BOOL=ON
        -D Trilinos_ENABLE_AztecOO:BOOL=ON
        -D Trilinos_ENABLE_Belos:BOOL=ON
        -D Trilinos_ENABLE_Epetra:BOOL=ON
        -D Trilinos_ENABLE_EpetraExt:BOOL=ON
        -D Trilinos_ENABLE_Galeri:BOOL=ON
        -D Trilinos_ENABLE_Ifpack2:BOOL=ON
        -D Trilinos_ENABLE_Ifpack:BOOL=ON
        -D Trilinos_ENABLE_Isorropia:BOOL=ON
        -D Trilinos_ENABLE_ML:BOOL=ON
        -D Trilinos_ENABLE_MueLu:BOOL=ON
        -D Trilinos_ENABLE_NOX:BOOL=ON
        -D Trilinos_ENABLE_Optika:BOOL=OFF
        -D Trilinos_ENABLE_TESTS:BOOL=OFF
        -D Trilinos_ENABLE_Teuchos:BOOL=ON
        -D Trilinos_ENABLE_Tpetra:BOOL=ON
        -D Trilinos_ENABLE_Zoltan2:BOOL=ON
    )
    codes_cmake_fix_lib_dir
    codes_cmake "${x[@]}"
    # may need to use "make -j1 install" in dev
    codes_make_install
}

#!/bin/bash
codes_dependencies metis

# https://trilinos.org/oldsite/download/download.html
codes_download_foss trilinos-12.10.1-Source.tar.gz
mkdir build
cd build
CC=mpicc CXX=mpicxx cmake \
  -DCMAKE_INSTALL_PREFIX:PATH="$(pyenv prefix)" \
  -DCMAKE_CXX_FLAGS:STRING="-DMPICH_IGNORE_CXX_SEEK -fPIC" \
  -DCMAKE_C_FLAGS:STRING="-DMPICH_IGNORE_CXX_SEEK -fPIC" \
  -DCMAKE_CXX_STANDARD:STRING="11" \
  -DCMAKE_Fortran_FLAGS:STRING="-fPIC" \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DMETIS_LIBRARY_DIRS="$(pyenv prefix)/lib" \
  -DTPL_ENABLE_DLlib:BOOL=OFF \
  -DTPL_ENABLE_QT:BOOL=OFF \
  -DTPL_ENABLE_MPI:BOOL=ON \
  -DTPL_ENABLE_BLAS:BOOL=ON \
  -DTPL_ENABLE_LAPACK:BOOL=ON \
  -DTPL_ENABLE_METIS:BOOL=ON \
  -DTPL_ENABLE_ParMETIS:BOOL=ON \
  -DTrilinos_ENABLE_Amesos:BOOL=ON \
  -DTrilinos_ENABLE_Amesos2:BOOL=ON \
  -DTrilinos_ENABLE_AztecOO:BOOL=ON \
  -DTrilinos_ENABLE_Belos:BOOL=ON \
  -DTrilinos_ENABLE_Epetra:BOOL=ON \
  -DTrilinos_ENABLE_EpetraExt:BOOL=ON \
  -DTrilinos_ENABLE_Galeri:BOOL=ON \
  -DTrilinos_ENABLE_Ifpack:BOOL=ON \
  -DTrilinos_ENABLE_Isorropia:BOOL=ON \
  -DTrilinos_ENABLE_ML:BOOL=ON \
  -DTrilinos_ENABLE_NOX:BOOL=ON \
  -DTrilinos_ENABLE_Optika:BOOL=OFF \
  -DTrilinos_ENABLE_Teuchos:BOOL=ON \
  -DTrilinos_ENABLE_Tpetra:BOOL=ON \
  -DTrilinos_ENABLE_TESTS:BOOL=OFF \
  ..
codes_make_install

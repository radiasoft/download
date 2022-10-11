#!/bin/bash

synergia_python_install() {
    cd synergia2
    synergia_patch_find_fftw3
    codes_cmake \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[pyenv_prefix]}" \
        -DFFTW3_LIBRARY_DIRS=/usr/lib64
    codes_make_install
}

synergia_main() {
    codes_dependencies common
    codes_download fnalacceleratormodeling/synergia2 devel3
}

synergia_patch_find_fftw3() {
    # TODO(e-carlin): discuss with rjn how to remove the posit and put the $BIVIO_MPI_LIB
    # in the patch. I don't want to escape all the $ so 'EOF' is nice but then I can't do
    # variable expansion
    # POSIT: $BIVIO_MPI_LIB
    patch CMake/FindFFTW3.cmake <<'EOF'
@@ -39,7 +39,7 @@
 set(FFTW3_MPI_NAMES ${FFTW3_MPI_NAMES} fftw3_mpi)

 find_library(FFTW3_MPI_LIBRARIES NAMES ${FFTW3_MPI_NAMES}
-    PATHS ${FFTW3_LIBRARY_DIRS}
+    PATHS /usr/lib64/mpich/lib
     NO_DEFAULT_PATH)
 if(FFTW3_MPI_LIBRARIES)
     set(FFTW3_MPI_FOUND TRUE)
EOF
}

#!/bin/bash

radia_main() {
    # needed for fftw and uti_*.py
    codes_dependencies srw
    codes_download ochubar/Radia
    # committed *.so files are not so good.
    find . -name \*.so -o -name \*.a -o -name \*.pyd -exec rm {} \;
    rm -rf ext_lib
    perl -pi - cpp/py/setup.py <<'EOF'
        s/\bfftw/sfftw/;
        s/mpi_cxx/mpi/;
        s{/usr/lib/openmpi/lib}{/usr/lib64/mpich/lib}g;
        s{/usr/lib/openmpi/include}{/usr/include/mpich-x86_64}g;
EOF
    perl -pi -e '
        s/-lfftw/-lsfftw/;
        s/\bcc\b/mpicc/;
        s/\bc\+\+/mpicxx/;
        # The MODE flag hardwires includes incorrectly
        s/^(LIBCFLAGS\s*=)/$1 -D_WITH_MPI /;
        ' cpp/gcc/Makefile
    radia_patch_py_ssize_t
    cd cpp/gcc
    make "-j$(codes_num_cores)" lib
}

radia_patch_py_ssize_t() {
    patch cpp/src/clients/python/pyparse.h <<'EOF'
@@ -17,7 +17,7 @@
 //#include <cstring>

 using namespace std;
-
+#define PY_SSIZE_T_CLEAN
 //Without the following Python.h will enforce usage of python**_d.lib in dbug mode, which may not be always existing
 //NOTE: to make it compilable with VC2013 (VC12), that blcock had to be moved down and placed after the previous includes
 #if defined(_DEBUG)
EOF
}

radia_python_install() {
    install_pip_install trimesh==4.9.0
    cd Radia/cpp/py
    MODE=mpi python setup.py build_ext
    codes_python_lib_copy "$(find . -name radia*.so)"
}

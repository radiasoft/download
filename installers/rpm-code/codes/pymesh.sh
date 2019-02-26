#!/bin/bash
codes_dependencies common
codes_yum_dependencies mpfr-devel gmp-devel
codes_download https://github.com/PyMesh/PyMesh.git
git submodule update --init
# fixes hardwired directories which breaks cmake
# also adds -j to pymesh cmake build
patch setup.py < setup.py.patch
NUM_CORES=$(codes_num_cores) codes_python_install
# run tests outside build directory
cd ..
python -c "import pymesh; pymesh.test()"

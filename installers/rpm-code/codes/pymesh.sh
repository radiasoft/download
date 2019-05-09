#!/bin/bash
codes_dependencies common
codes_yum_dependencies mpfr-devel gmp-devel
codes_download_nonrecursive=1 codes_download https://github.com/radiasoft/PyMesh.git
git submodule update --init --depth=50 third_party/geogram
# cgal is very large so use --depth=5
git submodule update --init --depth=5 $(find third_party/* -maxdepth 0 -type d | grep -v geogram)
NUM_CORES=$(codes_num_cores) codes_python_install
# run tests outside build directory
cd ..
python -c 'import pymesh; pymesh.test()'

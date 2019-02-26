#!/bin/bash
codes_dependencies common
codes_yum_dependencies mpfr-devel gmp-devel
codes_download https://github.com/PyMesh/PyMesh.git
git submodule update --init
# Runs out of memory on a VM if there are not enough cores
NUM_CORES=1 python setup.py build
codes_python_install
# run tests outside build directory
cd ..
python -c "import pymesh; pymesh.test()"

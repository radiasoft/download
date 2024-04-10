#!/bin/bash
: to_install_at_nersc <<'EOF'
# Hints for installing SRW at NERSC

## Install python
curl radia.run | bash -s nersc-pyenv

## Load fftw with:
module load  cray-fftw

## Install mpi4py
https://docs.nersc.gov/development/languages/python/parallel-python/#mpi4py-in-your-custom-conda-environment

## Install numpy with correct mkl
https://docs.nersc.gov/development/libraries/mkl/
MPICC="cc -mkl" pip install --force --no-cache-dir --no-binary=numpy numpy==

## Need to explicitly pass fftw lib dir when making srw python
LDFLAGS="-L$FFTW_ROOT/lib" make python
EOF

srw_main() {
    codes_yum_dependencies fftw2-devel
    codes_dependencies bnlcrl ml
}

srw_python_install() {
    install_pip_install primme
    install_pip_install srwpy==4.1.0
    _srw_srwpy_backwards_compatible
}

_srw_srwpy_backwards_compatible() {
    declare -a old_modules=(
        srwl_bl
        srwl_uti_brightness
        srwl_uti_cryst
        srwl_uti_mag
        srwl_uti_smp
        srwl_uti_smp_rnd_obj2d
        srwl_uti_smp_rnd_obj3d
        srwl_uti_src
        srwl_uti_und
        srwlib
        srwlpy
        uti_io
        uti_io_genesis
        uti_mag
        uti_math
        uti_math_eigen
        uti_parse
        uti_plot
        uti_plot_com
        uti_plot_matplotlib
    )

    declare d=$(codes_python_lib_dir)
    install -m 444 /dev/stdin $d/srwpy_import_warning.py <<EOF
import sys

displayed = False

def check(calling_module):
    global displayed
    if not displayed:
        displayed = True
        print(f"This method of importing {calling_module} is deprecated. Please change to import from srwpy (ex: import {calling_module} -> from srwpy import {calling_module})", file=sys.stderr)
EOF
    declare m
    for m in "${old_modules[@]}"; do
        install -m 444 /dev/stdin $d/$m.py <<EOF
from srwpy.$m import *
import srwpy_import_warning

srwpy_import_warning.check("$m")
EOF
    done
}

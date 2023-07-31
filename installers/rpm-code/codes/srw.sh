#!/bin/bash
: to_install_at_nersc <<'EOF'
# Hinsts for installing SRW at NERSC

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
    codes_download ochubar/SRW
    # committed *.so files are not so good.
    find . -name \*.so -o -name \*.a -o -name \*.pyd -exec rm {} \;
    perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
    perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
    cd cpp/gcc
    codes_make lib
}

srw_python_install() {
    install_pip_install primme
    install_pip_install srwpy==4.0.0.b1
    srw_srwpy_backwards_compatible
}

srw_srwpy_backwards_compatible() {
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

    cd /home/vagrant/.pyenv/versions/3.9.15/envs/py3/lib/python3.9/site-packages/
        cat > srwpy_import_warning.py <<EOF
displayed = False

def check(calling_module):
    global displayed
    if not displayed:
        displayed = True
        raise DeprecationWarning(f"This method of calling {calling_module} is deprecated. Please change to import from srwpy (ex: import {calling_module} -> from srwpy import {calling_module})")
EOF
    for i in "${old_modules[@]}"
    do
        cat > $i.py <<EOF
from srwpy.$i import *
import srwpy_import_warning

srwpy_import_warning.check("$i")
EOF
    done
}

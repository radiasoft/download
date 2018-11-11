#!/bin/bash
# needed for fftw and uti_*.py
codes_dependencies srw
radia_python_versions='2 3'

radia_python_install() {
    codes_download ochubar/Radia
    # committed *.so files are not so good.
    find . -name \*.so -exec rm {} \;
    rm -rf ext_lib
    cores=$(codes_num_cores)
    perl -pi -e "s/-j\\s*8/-j$cores/" Makefile
    perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
    perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
    make core
    make pylib
    local d=$(python -c 'import sys; from distutils.sysconfig import get_python_lib as g; sys.stdout.write(g())')
    local so=radia.so
    if (( $v >= 3 )); then
        so=${so/./.$(python -c 'import sys; from sysconfig import get_config_var as g; sys.stdout.write(g("SOABI"))').}
    fi
    (
        cd env/radia_python
        # do not install uti_* because get those from SRW
        install -m 644 "$so" "$d"
    )
}

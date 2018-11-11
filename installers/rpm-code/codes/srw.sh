#!/bin/bash
codes_yum_dependencies fftw2-devel
codes_dependencies bnlcrl
srw_python_versions='2 3'

srw_python_install() {
    local v=$1
    codes_download ochubar/SRW
    # committed *.so files are not so good.
    find . -name \*.so -exec rm {} \;
    cores=$(codes_num_cores)
    perl -pi -e "s/-j\\s*8/-j$cores/" Makefile
    perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
    perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
    make
    local d=$(python -c 'import sys; from distutils.sysconfig import get_python_lib as g; sys.stdout.write(g())')
    local so=srwlpy.so
    if (( $v >= 3 )); then
        so=${so/./.$(python -c 'import sys; from sysconfig import get_config_var as g; sys.stdout.write(g("SOABI"))').}
    fi
    (
        cd env/work/srw_python
        install -m 644 {srwl,uti}*.py "$so" "$d"
    )
}

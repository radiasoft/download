#!/bin/bash
set -euo pipefail

rsmake_lib_dir() {
    python <<'EOF'
import sys
from distutils.sysconfig import get_python_lib as x
sys.stdout.write(x())
EOF
}

rsmake_main() {
    local cores=$(nproc)
    if (( cores > 2 )); then
        cores=$(( cores / 2 ))
    fi
    # ext_lib is not used so remove it so it doesn't get built
    # and use as a sentinel for remove any object files the first time.
    if [[ -d ext_lib ]]; then
        find . -name \*.so -o -name \*.a -o -name \*.pyd -exec rm {} \;
        rm -rf ext_lib
    fi
    # idemotent so always run these
    perl -pi -e "s/-j\\s*8/-j$cores/" Makefile
    perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
    perl -pi -e '
        s/-lfftw/-lsfftw/;
        s/\bcc\b/gcc/;
        s/\bc\+\+/g++/;
        # Stop "make lib" from rebuilding every time
        s/(?=^\s+rm -f \*.o\s*$)/#/;
    ' cpp/gcc/Makefile
    cd cpp/gcc
    make -j"$cores" lib
    cd ../..
    set +euo pipefail
    source ~/.bashrc
    set -euo pipefail
    local p
    for p in py2 py3; do
        pyenv activate "$p"
        make pylib
        install -m 555 env/radia_python/radia*.so "$(rsmake_lib_dir)"
        find . -name radia\*.so -exec rm {} \;
    done
    echo 'NOTE: uti*.py are installed with SRW, not Radia'
}

rsmake_main "$@"

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
    if [[ -d ext_lib ]]; then
        find . -name \*.so -o -name \*.a -o -name \*.pyd -exec rm {} \;
        rm -rf ext_lib
    fi
    # idemotent so always do
    perl -pi -e "s/-j\\s*8/-j$cores/" Makefile
    perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
    # ar -cvq is incorrect, really want crv
    perl -pi -e 's/-lfftw/-lsfftw/; s/-cvq/crv/; s/\bcc\b/gcc/; s/\bc\+\+/g++/; s/(?<=rm -f)/#/' cpp/gcc/Makefile
    cd cpp/gcc
    echo 'NOTE: uti*.py are installed with SRW, not Radia'
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
}

rsmake_main "$@"

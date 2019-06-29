#!/bin/bash

set -euo pipefail

rsmake_err() {
    echo ERROR: "$@" 1>&2
    return 1
}

rsmake_main() {
    local pp=$(pyenv prefix)
    if [[ ! $pp =~ /py2$ ]]; then
        rsmake_err "wrong python environment=$(pyenv version-name), only py2 supported"
    fi
    local cores=$(nproc)
    if (( cores > 2 )); then
        cores=$(( cores / 2 ))
    fi
    if [[ ! -d build ]]; then
        if [[ ! -d config ]]; then
            if [[ ! -d contractor ]]; then
                if [[ $(git symbolic-ref --short HEAD) == master ]]; then
                    git checkout devel
                fi
                ./bootstrap
            fi
            ./contract.py --configure default_parallel="$cores" \
                synergia2/repo=https://bitbucket.org/robnagler/synergia2 \
                chef-libs/make_use_custom_parallel=1 \
                chef-libs/make_custom_parallel=1 \
                bison_internal=1 \
                fftw3_internal=1 \
                libpng_internal=1 \
                nlopt_internal=1
        fi
    fi
    if [[ -d build/synergia2 ]]; then
        local root=$PWD
        cd build/synergia2
        if [[ $(find CMake CMakeLists.txt -newer Makefile) ]]; then
            cmake -DCMAKE_INSTALL_PREFIX:PATH="$root"/install \
                -DBoost_INCLUDE_DIR=/usr/include \
                -DBOOST_LIBRARYDIR:PATH=/usr/lib64 \
                -DFFTW3_LIBRARY_DIRS:PATH="$root"/install/lib \
                -DCMAKE_BUILD_TYPE=Release \
                "$root"/build/synergia2
        fi
        make -j "$cores"
        make install
        cd ../..
    else
        ./contract.py
    fi
    #TODO(robnagler) change to $BIVIO_MPI_PREFIX after home-env released
    perl -pi -e '
        s{(?<=install_dir/lib)}{/synergia};
        s{(?=ldpathadd ")}{ldpathadd BIVIO_MPI_PREFIX/lib\n}s;
    ' install/bin/synergia
    # Synergia installer doesn't set modes correctly in all cases
    chmod -R a+rX install
    cd install
    cp -a bin include "$pp"
    local l="$pp/lib/synergia"
    install -d -m 755 "$l"
    cp -a lib/* "$l"
    local lp="$l"/python2.7/site-packages
    mv "$lp"/* "$l"
    cd ..
    # sanity check that the directory is empty
    if ! rmdir "$lp" "$(dirname "$lp")"; then
        rsmake_err "packages directory=$lp: not empty install failed"
    fi
}

rsmake_main "$@"

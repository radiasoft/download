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
        cd build/synergia2
        make -j "$cores"
        make install
        cd ../..
    else
        ./contract.py
    fi
    perl -pi -e '
        s{(?<=install_dir/lib)}{/synergia};
        s{(?=ldpathadd ")}{ldpathadd /usr/lib64/openmpi/lib\n}s;
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

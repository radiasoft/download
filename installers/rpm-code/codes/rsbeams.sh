#!/bin/bash

_rsbeam_codes=(
    rsbeams
    rsflash
    rslaser
    rsoopic
    rsopt
    rswarp
)

rsbeams_main() {
    rsbeams_init_vars
    codes_dependencies common ml
    declare r
    for r in "${_rsbeam_codes[@]}"; do
        codes_download radiasoft/"$r"
        cd ..
    done
}

rsbeams_init_vars() {
    if install_version_fedora_lt_36; then
        _rsbeam_codes+=('rssynergia')
    fi
}

rsbeams_python_install() {
    install_pip_install DFO-LS Libensemble yt
    declare r
    for r in "${_rsbeam_codes[@]}"; do
        cd "$r"
        codes_python_install
        cd ..
    done
}

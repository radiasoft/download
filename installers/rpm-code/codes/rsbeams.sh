#!/bin/bash

_rsbeam_codes=( rsbeams rssynergia rsoopic rswarp )

rsbeams_main() {
    codes_dependencies common ml
    local r
    for r in "${_rsbeam_codes[@]}"; do
        codes_download radiasoft/"$r"
        cd ..
    done
}

rsbeams_python_install() {
    pip install nlopt DFO-LS Libensemble
    cd libensemble
    codes_python_install
    cd ..
    local r
    for r in "${_rsbeam_codes[@]}"; do
        cd "$r"
        codes_python_install
        cd ..
    done
}

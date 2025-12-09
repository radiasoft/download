#!/bin/bash

_rsbeam_codes=(
    rsbeams
    rsflash
    rslaser
    rsopt
)

rsbeams_main() {
    codes_dependencies common ml
    declare r
    for r in "${_rsbeam_codes[@]}"; do
        codes_download radiasoft/"$r"
        cd ..
    done
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

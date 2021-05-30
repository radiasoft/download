#!/bin/bash

_rsbeam_codes=(
    rsbeams
    rsflash
    rslaser
    rsoopic
    rssynergia
    rswarp
)

rsbeams_main() {
    codes_dependencies common ml
    local r
    for r in "${_rsbeam_codes[@]}"; do
        codes_download radiasoft/"$r"
        cd ..
    done
}

rsbeams_python_install() {
    # https://github.com/jupyter/notebook/issues/2435
    # yt installs jedi, which needs to be forced to 0.17.2
    # keep consistent with container-conf build.sh
    install_pip_install jedi==0.17.2
    install_pip_install nlopt DFO-LS Libensemble yt
    local r
    for r in "${_rsbeam_codes[@]}"; do
        cd "$r"
        codes_python_install
        cd ..
    done
}

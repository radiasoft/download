#!/bin/bash
#
# To run: curl radia.run | bash -s warp
#

warp_main() {
    if [[ -z $NERSC_HOST ]]; then
        install_repo code warp
        return $?
    fi
    if [[ $NERSC_HOST != cori ]]; then
        install_msg 'Only NERSC host supported at this time is cori'
        return $?
    fi
    local root=$SCRATCH/radia
    mkdir -p "$root"
    local script=$root/warp.sh
    install_download warp.sh > "$script"
    install_msg "To setup the environ and build WARP with PICSAR, run:
source '$script'
"
}

warp_main

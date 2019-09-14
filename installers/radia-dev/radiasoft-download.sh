#!/bin/bash
#
# To run: curl radia.run | bash -s radia-dev
#

radia_dev_main() {
    local cd=
    if [[ $(basename "$(pwd)") != Radia ]]; then
        if [[ ! -d Radia ]]; then
            git clone https://github.com/ochubar/Radia.git
        fi
        cd Radia
        cd='cd Radia
'
    fi
    #TODO(robnagler) remove once home-env updated
    install_download rsmake.sh > rsmake
    chmod +x rsmake
    install_msg "Radia is downloaded. To compile and install:
${cd}./rsmake"
}

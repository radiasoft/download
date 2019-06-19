#!/bin/bash
#
# To run: curl radia.run | bash -s synergia-dev
#

synergia_dev_main() {
    local cd=
    if [[ $(basename "$(pwd)") != contract-synergia2 ]]; then
        if [[ ! -d contract-synergia2 ]]; then
            git clone https://bitbucket.org/fnalacceleratormodeling/contract-synergia2.git
        fi
        cd contract-synergia2
        cd='cd contract-synergia2
'
    fi
    install_download rsmake.sh > rsmake
    chmod +x rsmake
    install_msg "Synergia is downloaded. To compile and install:
${cd}./rsmake"
}

synergia_dev_main "$@"

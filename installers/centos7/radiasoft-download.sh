#!/bin/bash
#
# To run: curl radia.run | bash -s centos7 op ...
#
centos7_main() {
    local op=$1
    shift
    install_extra_args=( "$@" )
    install_url radiasoft/centos7/script
    if [[ $op =~ / ]]; then
        install_err "$op: unknown operation"
    fi
    install_script_eval "$(basename "$op" .sh).sh"
}

centos7_main "${install_extra_args[@]}"

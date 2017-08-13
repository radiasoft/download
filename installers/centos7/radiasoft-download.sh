#!/bin/bash
#
# To run: curl radia.run | bash -s centos7 op ...
#
centos7_main() {
    local op=$1
    shift
    local a=( "$@" )
    install_url radiasoft/centos7
    if [[ $op =~ / ]]; then
        install_err "$op: unknown operation"
    fi
    local f=$(basename "$op" .sh)
    install_script_eval "script/$f.sh"
    "${f//-/_}_main" "${a[@]}"
}

centos7_main "${install_extra_args[@]}"

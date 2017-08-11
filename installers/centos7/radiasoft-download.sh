#!/bin/bash
#
# centos7 install
#
centos7_main() {
    local op=$1
    shift
    install_extra_args=( "$@" )
    install_script_eval "$op.sh"
}

centos7_main "${install_extra_args[@]}"

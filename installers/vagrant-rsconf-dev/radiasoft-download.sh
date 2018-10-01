#!/bin/bash
#
# Create a rsconf dev box
#
set -euo pipefail
vagrant_rsconf_dev_main() {
    if [[ ${1:-} != master ]]; then
        export vagrant_dev_barebones=1 vagrant_dev_no_docker_disk=
    fi
    install_repo_eval vagrant-centos7
}

vagrant_rsconf_dev_main ${install_extra_args[@]+"${install_extra_args[@]}"}

#!/bin/bash
#
# Create a rsconf dev box
#
set -euo pipefail

vagrant_rsconf_dev_main() {
    if [[ ${1:-} != master ]]; then
        export vagrant_dev_barebones=1 install_server=http://v3.radia.run:2916 install_channel=dev
    fi
    install_repo_eval vagrant-centos7
    if [[ ${1:-} == master ]]; then
        return
    fi
    bivio_vagrant_ssh sudo su - <<EOF
export install_channel=dev install_server="$install_server"
# fails because of reboot
curl "$install_server" | bash -s rsconf.sh "\$(hostname -f)" setup_dev || true
EOF
    vagrant reload
    bivio_vagrant_ssh sudo su - <<EOF
set -e -x
export install_channel=$install_channel install_server=$install_server
curl "$install_server" | bash -s rsconf.sh "\$(hostname -f)" setup_dev
EOF
}

vagrant_rsconf_dev_main ${install_extra_args[@]+"${install_extra_args[@]}"}

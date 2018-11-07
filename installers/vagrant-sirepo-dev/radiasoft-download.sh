#!/bin/bash
#
# Create a Fedora 27 VirtualBox for sirepo
#
# Usage: curl radia.run | bash -s vagrant-sirepo-dev [guest-name:v.radia.run [guest-ip:10.10.10.10]]
#
vagrant_sirepo_dev_main() {
    install_repo_eval vagrant-dev fedora "$@"
    vagrant ssh <<EOF
export install_server='$install_server' install_channel='$install_channel' install_debug='$install_debug'
source ~/.bashrc
radia_run sirepo-dev
EOF
}

vagrant_sirepo_dev_main ${install_extra_args[@]+"${install_extra_args[@]}"}

#!/bin/bash
vagrant_sirepo_dev_main() {
    install_repo_eval vagrant-dev fedora "$@"
    vagrant ssh <<EOF
export install_server='$install_server' install_channel='$install_channel' install_debug='$install_debug'
source ~/.bashrc
radia_run sirepo-dev
EOF
}

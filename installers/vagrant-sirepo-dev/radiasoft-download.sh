#!/bin/bash
vagrant_sirepo_dev_main() {
    install_repo_eval vagrant-dev fedora "$@"
    vagrant ssh <<EOF
$(install_vars_export)
source ~/.bashrc
radia_run sirepo-dev
EOF
}

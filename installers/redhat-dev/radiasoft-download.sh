#!/bin/bash
#
# To run: curl radia.run | bash -s redhat-dev
#
redhat_dev_main() {
    if [[ ! -r /etc/redhat-release ]]; then
        install_err 'only works on Red Hat flavored Linux'
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant (or other ordinary user), not root'
    fi
    install_repo_as_root redhat-base
    install_repo_as_root home
    install_repo_eval home
}

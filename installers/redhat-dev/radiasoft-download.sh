#!/bin/bash
#
# To run: curl radia.run | bash -s redhat-dev
#
redhat_dev_fix_git_nfs_permissions() {
    declare no_fix_git_nfs_permissions=${1:+1}
    if [[ $no_fix_git_nfs_permissions ]]; then
        return
    fi
    git config --global --add safe.directory '*'
}

redhat_dev_main() {
    if [[ ! $install_os_release_id =~ fedora|centos|rhel ]]; then
        install_err "only works on Red Hat flavored Linux (os=$install_os_release_id)"
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant (or other ordinary user), not root'
    fi
    install_yum update
    if [[ $install_os_release_id == fedora ]]; then
        # this is a very an annoying feature, because it happens in every interactive shell
        install_sudo rm -f /etc/profile.d/console-login-helper-messages-profile.sh
    fi
    install_repo_as_root redhat-base
    # POSIT: redhat-base installs git
    redhat_dev_fix_git_nfs_permissions ${1:+1}
    install_repo_as_root home
    install_repo_eval home
}

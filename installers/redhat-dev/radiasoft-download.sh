#!/bin/bash
#
# To run: curl radia.run | bash -s redhat-dev
#
redhat_dev_main() {
    if [[ $install_os_release_id =~ fedora|centos|rhel ]]; then
        install_err 'only works on Red Hat flavored Linux'
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant (or other ordinary user), not root'
    fi
    install_yum update
    if [[ $install_os_release_id == fedora && $install_os_release_version_id == 29 ]]; then
        # Fixed in yum update, but need to restart and reset failed
        # https://bugzilla.redhat.com/show_bug.cgi?id=1158846
        if [[ $(systemctl is-failed nfs-idmapd) == failsed ]]; then
            systemctl reset-failed
            systemctl restart nfs-idmapd
        fi
        # this is a very an annoying feature, because it happens in every interactive shell
        rm -f /etc/profile.d/console-login-helper-messages-profile.sh
    fi
    install_repo_as_root redhat-base
    install_repo_as_root home
    install_repo_eval home
}

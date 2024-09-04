#!/bin/bash
#
# To run: curl radia.run | bash -s redhat-dev
#
redhat_dev_main() {
    if ! install_os_is_redhat; then
        install_err "only works on Red Hat flavored Linux (os=$install_os_release_id)"
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant (or other ordinary user), not root'
    fi
    if install_os_is_centos_7; then
        install_sudo sed -i.bak -e 's,^mirrorlist=http://mirrorlist,#mirrorlist=http://vault,' -e 's,^#baseurl=http://mirror.centos.org,baseurl=https://depot.radiasoft.org/yum,' /etc/yum.repos.d/CentOS-Base.repo
        install_yum clean all
        install_yum makecache
    fi
    install_yum update
    if install_os_is_fedora; then
        # this is a very an annoying feature, because it happens in every interactive shell
        install_sudo rm -f /etc/profile.d/console-login-helper-messages-profile.sh
    fi
    install_repo_as_root redhat-base
    install_repo_as_root home
    install_repo_eval home
}

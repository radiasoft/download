#!/bin/bash
#
# Create a CentOS 7 VirtualBox for perl development
#
# Usage: radia_run vagrant-perl-dev [guest-name:v.radia.run [guest-ip:10.10.10.10]]
#
vagrant_perl_dev_main() {
    install_repo_eval vagrant-dev centos/7 "$@"
    vagrant ssh <<EOF
$(install_vars_export)
source ~/.bashrc
radia_run perl-dev
EOF
}

vagrant_perl_dev_main ${install_extra_args[@]+"${install_extra_args[@]}"}

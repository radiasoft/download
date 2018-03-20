#!/bin/bash
#
# Create a CentOS 7 VirtualBox for perl development
#
# Usage: radia_run vagrant-perl-dev [guest-name:v.radia.run [guest-ip:10.10.10.10]]
#
vagrant_perl_dev_main() {
    install_repo_eval vagrant-dev centos/7 "$@"
    vagrant ssh <<EOF
export install_server='$installer_server' install_channel='$install_channel' install_debug='$install_debug'
radia_run biviosoftware/container-perl
su - vagrant <<'EOF2'
cat >> ~/.pre_bivio_bashrc <<'EOF3'
export BIVIO_WANT_PERL=1
export BIVIO_HTTPD_PORT=8000
EOF3
. ~/.bashrc
_bivio_home_env_update -f
. ~/.bashrc
bivio sql init_dbms
ctd
EOF2
EOF
}

vagrant_perl_dev_main "${install_extra_args[@]}"

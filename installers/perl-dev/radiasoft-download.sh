#!/bin/bash
#
# To run: curl radia.run | bash -s perl-dev
#
perl_dev_main() {
    if ! fgrep -s -q ' release 7.' /etc/redhat-release; then
        install_err 'only works on CentOS/7 (RHEL/7) Linux'
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant (or other ordinary user), not root'
    fi
    if ! grep -s -q BIVIO_WANT_PERL=1 ~/.pre_bivio_bashrc; then
        cat >> ~/.pre_bivio_bashrc <<'EOF'
export BIVIO_WANT_PERL=1
export BIVIO_HTTPD_PORT=8000
EOF
    fi
    if ! perl -MGMP::Mpf -e 1 2>&1; then
        install_repo_as_root biviosoftware/container-perl
    fi
    if [[ $(psql 2>&1) =~ could.not.connect ]]; then
        sudo su - <<'EOF'
set -e
rpm -q postgresql-server >&/dev/null || yum install -y -q postgresql-server
postgresql-setup initdb
install -m 600 -o postgres -g postgres /var/lib/pgsql/data/pg_hba.conf <<'EOF2'
local all all trust
EOF2
systemctl start postgresql
systemctl enable postgresql
EOF
    fi
    set +euo pipefail
    . ~/.bashrc
    _bivio_home_env_update -f
    . ~/.bashrc
    bivio sql init_dbms >& /dev/null || true
    # always recreate db
    ctd
}

perl_dev_main "${install_extra_args[@]}"

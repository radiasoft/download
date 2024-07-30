#!/bin/bash
#
# To run: curl radia.run | bash -s perl-dev
#
perl_dev_main() {
    if ! install_os_is_rhel_compatible; then
        install_err 'only works on RHEL like Linux'
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
    if ! perl -MGMP::Mpf -e 1 >& /dev/null; then
        install_repo_as_root biviosoftware/container-perl base
        install_yum_install "$(install_foss_server)"/bivio-perl-dev.rpm
    fi
    if [[ $(psql 2>&1) =~ could.not.connect ]]; then
        install_sudo su - <<'EOF'
set -e
rpm -q postgresql-server >&/dev/null || yum install -y -q postgresql-server
PGSETUP_INITDB_OPTIONS="--encoding=SQL_ASCII" postgresql-setup initdb
install -m 600 -o postgres -g postgres /dev/stdin /var/lib/pgsql/data/pg_hba.conf <<'EOF2'
local all all trust
EOF2
systemctl start postgresql
systemctl enable postgresql
EOF
    fi
    if [[ ! -e ~/bconf.d/defaults.bconf ]]; then
        mkdir -p ~/bconf.d
cat > ~/bconf.d/defaults.bconf <<'EOF'
{
    'Bivio::Die' => {
#       stack_trace_error => 1,
#       stack_trace => 1,
    },
    'Bivio::IO::Alert' => {
#       stack_trace_warn => 1,
#       stack_trace_warn_deprecated => 1,
        max_arg_length => 1000000,
        max_element_count => 100,
        max_arg_depth => 5,
    },
    'Bivio::Biz::Action::AssertClient' => {
#       hosts => [qw()],
    },
    'Bivio::Test::Language::HTTP' => {
        mail_tries => 5,
    },
    'Bivio::IO::Trace' => {
#       command_line_arg => '/sql|ec/i',
#       package_filter => '/Agent|Task|Model/',
#       call_filter => '!grep(/Can.t locate/, @$msg)',
    },
};
EOF
    fi
    install_source_bashrc
    _bivio_home_env_update -f
    # Needed for bashrc_b_env_aliases to contain complete set
    cd ~/src/biviosoftware
    gcl perl-Artisans
    ln -s ../biviosoftware/perl-Artisans ~/src/perl/Artisans
    cd
    install_source_bashrc
    b_pet
    bivio sql init_dbms || true
    # always recreate db
    ctd
}

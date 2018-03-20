#!/bin/bash
#
# To run: curl radia.run | bash -s perl-dev
#
perl_dev_main() {
    if [[ ! -r /etc/redhat-release ]]; then
        install_err 'only works on Red Hat flavored Linux'
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
    if ! perl -MGMP -e 1 >& /dev/null; then
        sudo su - -c 'radia_run biviosoftware/container-perl'
    fi
    BIVIO_WANT_PERL=1 _bivio_home_env_update -f
    set +euo pipefail
    . ~/.bashrc
    bivio sql init_dbms >& /dev/null || true
    # always recreate db
    ctd
}

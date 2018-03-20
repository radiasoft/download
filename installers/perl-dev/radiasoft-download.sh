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
    install -m 600 /dev/stdin ~/.pre_bivio_bashrc <<'EOF'
export BIVIO_WANT_PERL=1
export BIVIO_HTTPD_PORT=8000
EOF
    install_repo_as_root biviosoftware/container-perl
    set +e
    . ~/.bashrc
    bivio sql init_dbms >& /dev/null || true
    # always recreate db
    ctd
}

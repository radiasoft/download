#!/bin/bash
#
# Assumes running in GITHUB
#
ci_pull_request_main() {
    if [[ ${GITHUB_EVENT_NAME:-} != pull_request ]]; then
        install_err "GITHUB_EVENT_NAME=${GITHUB_EVENT_NAME:-} not pull_request"
    fi
    if [[ ! -r setup.py ]]; then
        install_err 'no setup.py'
    fi
    local i
    local p=0
    local r=$(basename "${GITHUB_REPOSITORY:-MISSING}")
    case $r in
        pykern)
            i=radiasoft/python3
            ;;
        sirepo)
            i=radiasoft/beamsim
            p=1
            ;;
        MISSING)
            install_err '$GITHUB_REPOSITORY no set'
            ;;
        *)
            i=radiasoft/sirepo
            ;;
    esac
    local d=$PWD
    docker run -i -u root --rm "$i:alpha" bash <<EOF | cat
        set -eou pipefail
        chown -R vagrant: .
        cd '$d'
        su - vagrant <<EOF2
            set -eou pipefail
            if (( $p )); then
                pip uninstall -y pykern >& /dev/null || true
                pip install git+https://github.com/radiasoft/pykern.git
            fi
            pip uninstall -y '$r' >& /dev/null || true
            pip install -e .
            pykern test
EOF2
EOF
}

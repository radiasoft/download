#!/bin/bash
#
# Assumes running in GITHUB
#
python_ci_main() {
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
        rsconf)
            i=radiasoft/python3
            p=1
            ;;
        sirepo)
            i=radiasoft/sirepo-ci
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
    local o=$(stat --format='%u:%g' "$d")
    set -x
    docker run -v "$d:$d" -i -u root --rm "$i:alpha" bash <<EOF | cat
        set -eou pipefail
        set -x
        cd '$d'
        chown -R vagrant: '$d'
        # POSIT: no interpolated vars in names
        trap 'chown -R "$o" "$d"' EXIT
        su - vagrant <<EOF2
            set -eou pipefail
            set -x
            cd '$d'
            if (( $p )); then
                pip uninstall -y pykern >& /dev/null || true
                pip install git+https://github.com/radiasoft/pykern.git
            fi
            pip uninstall -y '$r' >& /dev/null || true
            pip install -e .
            if [[ -f test.sh ]]; then
                bash test.sh
            else
                pykern ci run
            fi
EOF2
EOF
    set +x
}

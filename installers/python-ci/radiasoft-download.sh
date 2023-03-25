#!/bin/bash
#
# Assumes running in GITHUB
#
python_ci_main() {
    if [[ ! -r setup.py ]]; then
        install_err 'no setup.py'
    fi
    declare i
    declare -a p=()
    declare r=$(basename "${GITHUB_REPOSITORY:-MISSING}")
    case $r in
        pykern)
            i=radiasoft/python3
            ;;
        rsaccounting|rsconf)
            i=radiasoft/python3
            p+=( pykern )
            ;;
        sirepo)
            i=radiasoft/sirepo-ci
            p+=( pykern )
            ;;
        MISSING)
            install_err '$GITHUB_REPOSITORY no set'
            ;;
        *)
            i=radiasoft/sirepo
            p+=( pykern sirepo )
            ;;
    esac
    declare d=$PWD
    declare o=$(stat --format='%u:%g' "$d")
    set -x
    docker run -v "$d:$d" -i -u root --rm "$i:alpha" bash <<EOF | cat
        set -eou pipefail
        set -x
        cd '$d'
        chown -R vagrant: '$d'
        # POSIT: no interpolated vars in names
        trap 'chown -R "$o" "$d"' EXIT
        su - vagrant <<'EOF2'
            set -eou pipefail
            cd '$d'
            export GITHUB_TOKEN='${GITHUB_TOKEN:-}'
            # POSIT: no spaces or specials in $p values
            for x in ${p[*]}; do
                pip uninstall -y \$x >& /dev/null || true
                pip install git+https://'${GITHUB_TOKEN:+$GITHUB_TOKEN@}'github.com/radiasoft/\$x.git
            done
            pip uninstall -y '$r' >& /dev/null || true
            pip install -e .
            export PYKERN_PKCLI_TEST_MAX_FAILURES=1
            if [[ -f test.sh ]]; then
                bash test.sh
            else
                pykern ci run
            fi
EOF2
EOF
    set +x
}

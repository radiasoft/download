#!/bin/bash
#
# Requires GITHUB_REPOSITORY and accepts GITHUB_TOKEN
#
python_ci_main() {
    if ! [[ -r setup.py || -r pyproject.toml ]]; then
        install_err 'no setup.py or pyproject.toml'
    fi
    declare i
    declare -a p=()
    declare r=$(basename "${GITHUB_REPOSITORY:-MISSING}")
    case $r in
        pykern|chronver)
            i=radiasoft/python3
            ;;
        sirepo)
            i=radiasoft/sirepo-ci
            p+=( pykern )
            ;;
        MISSING)
            install_err '$GITHUB_REPOSITORY no set'
            ;;
        *)
            p+=( pykern )
            if grep sirepo $(ls setup.py pyproject.toml 2>/dev/null) /dev/null &> /dev/null; then
                i=radiasoft/sirepo
                p+=( sirepo )
            else
                i=radiasoft/python3
            fi
            ;;
    esac
    declare d=$PWD
    declare o=$(stat --format='%u:%g' "$d")
    set -x
    $RADIA_RUN_OCI_CMD run -v "$d:$d" -i -u root --rm "$i:alpha" bash <<EOF | cat
        set -eou pipefail
        ${install_debug:+set -x}
        cd '$d'
        chown -R vagrant: '$d'
        # POSIT: no interpolated vars in names
        trap 'chown -R "$o" "$d"' EXIT
        su - vagrant <<'EOF2'
            set -eou pipefail
            ${install_debug:+set -x}
            cd '$d'
            export GITHUB_TOKEN='${GITHUB_TOKEN:-}'
            # POSIT: no spaces or specials in repo names
            declare x
            _pip() { pip --disable-pip-version-check --no-color --quiet "\$@"; }
            for x in ${p+${p[*]}}; do
                _pip uninstall -y \$x >& /dev/null || true
                _pip install git+https://'${GITHUB_TOKEN:+$GITHUB_TOKEN@}'github.com/radiasoft/\$x.git
            done
            _pip uninstall -y '$r' >& /dev/null || true
            # GitHub CI runners are limited on disk space so use --no-cache-dir to limit disk usage as much as
            # possible. See git.radiasoft.org/downloads/issues/562
            _pip install --no-cache-dir -e .
            export PYKERN_PKCLI_TEST_MAX_FAILURES=1 PYKERN_PKCLI_TEST_RESTARTABLE=1
            if [[ -f test.sh ]]; then
                bash test.sh
            else
                pykern ci run
            fi
EOF2
EOF
    set +x
}

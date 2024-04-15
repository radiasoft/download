#!/bin/bash
#
# To run: curl radia.run | bash -s sirepo-ci-build
#
sirepo_ci_build_main() {
    if (( $EUID != 0 )); then
        echo 'must be run as root' 1>&2
        return 1
    fi
    install_source_bashrc
    install_tmp_dir
    local x=$PWD/build-ci
    local y=$PWD/run-ci
    # #! has to be first in file
    cat > "$x" <<EOF
#!/bin/bash
        base=\$1
        source ~/.bashrc
        set -euo pipefail
        $(install_vars_export)
        cd ~/src/radiasoft/container-sirepo-ci
        sirepo_ci_base=\$base build_docker_post_hook=$y radia_run container-build
EOF
    cat > "$y" <<EOF
#!/bin/bash
        image=\$1
        shift
        set -euo pipefail
        $RADIA_RUN_OCI_CMD run -i "\$@" \$image bash <<'EOF2'
            source ~/.bashrc
            set -eou pipefail
            $(install_vars_export)
            set -x
            mkdir -p ~/src/radiasoft
            cd ~/src/radiasoft
            pip uninstall -y pykern >& /dev/null || true
            gcl pykern
            cd pykern
            pip install -e .
            export PYKERN_PKCLI_TEST_MAX_FAILURES=1 PYKERN_PKCLI_TEST_RESTARTABLE=1
            pykern ci run
            cd ..
            gcl sirepo
            cd sirepo
            pip install -e .
            bash test.sh
EOF2
EOF
    chmod +x "$x" "$y"
    cd ~/src/radiasoft
    gcl container-beamsim
    gcl container-sirepo-ci
    cd container-beamsim
    build_docker_post_hook=$x install_repo_eval container-build
}

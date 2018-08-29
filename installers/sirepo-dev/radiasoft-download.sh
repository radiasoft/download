#!/bin/bash

sirepo_dev_main() {
    if [[ ! -r /etc/redhat-release ]]; then
        install_err 'only works on Red Hat flavored Linux'
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant (or other ordinary user), not root'
    fi
    set +e
    . ~/.bashrc
    set -e
    if ! [[ $(type -t pyenv) && $(pyenv version-name) == py2 ]]; then
        install_repo_as_root code-base
        bivio_pyenv_2
        set +e
        . ~/.bashrc
        set -e
    fi
    if ! type synergia >& /dev/null; then
        install_repo_eval beamsim-codes
    fi
    mkdir -p ~/src/radiasoft
    cd ~/src/radiasoft
    local p
    for p in pykern sirepo; do
        pip uninstall -y "$p" >& /dev/null || true
        if [[ -d $p ]]; then
            cd "$p"
            git pull
        else
            gcl "$p"
            cd "$p"
        fi
        if [[ -r requirements.txt ]]; then
            pip install -r requirements.txt >& /dev/null
        fi
        pip install -e .
        cd ..
    done
}

sirepo_dev_main "${install_extra_args[@]}"

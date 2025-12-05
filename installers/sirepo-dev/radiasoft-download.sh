#!/bin/bash

sirepo_dev_main() {
    if ! install_os_is_fedora; then
        install_err 'only works on Fedora Linux'
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant (or other ordinary user), not root'
    fi
    install_source_bashrc
    install_repo_eval beamsim-codes
    install_yum_install fedora-workstation-repositories
    install_yum_repo_set_enabled google-chrome
    install_yum install google-chrome-stable
    # rerun source, because beamsim-codes installs pyenv
    install_source_bashrc
    mkdir -p ~/src/radiasoft
    cd ~/src/radiasoft
    for p in pykern sirepo; do
        install_pip_uninstall "$p"
        if [[ -d $p ]]; then
            cd "$p"
            git pull &> /dev/null || true
        else
            gcl "$p"
            cd "$p"
        fi
        if [[ -r requirements.txt ]]; then
            install_pip_install -r requirements.txt >& /dev/null
        fi
        install_pip_install -e .
        cd ..
    done
    cd sirepo
    sirepo_dev_npm_global
}

sirepo_dev_npm_global() {
    if ! [[ $(type -p karma) && $(type -p jshint) ]]; then
       npm install -g \
           $(jq -r '.devDependencies | to_entries | map("\(.key)@\(.value)") | .[]' package.json)
    fi
}

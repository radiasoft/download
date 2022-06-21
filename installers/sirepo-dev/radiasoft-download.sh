#!/bin/bash

sirepo_dev_main() {
    if [[ $install_os_release_id != fedora ]]; then
        install_err 'only works on Fedora Linux'
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant (or other ordinary user), not root'
    fi
    install_source_bashrc
    local p
    # remove old packages, if they exist
    for p in Forthon H5hut openPMD ml_for_py3 raydata; do
        install_yum remove -y rscode-"$p" >& /dev/null || true
    done
    sirepo_dev_codes_only=1 install_repo_eval beamsim-codes
    install_yum install fedora-workstation-repositories
    install_yum config-manager --set-enabled google-chrome
    install_yum install google-chrome-stable
    # rerun source, because beamsim-codes installs pyenv
    install_source_bashrc
    mkdir -p ~/src/radiasoft
    cd ~/src/radiasoft
    pyenv global py3
    for p in pykern sirepo; do
        install_pip_uninstall "$p"
        if [[ -d $p ]]; then
            cd "$p"
            git pull
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
    cd ..
}

sirepo_dev_npm_global() {
    if ! [[ $(type -p karma) && $(type -p jshint) ]]; then
       npm install -g \
           $(jq -r '.devDependencies | to_entries | map("\(.key)@\(.value)") | .[]' package.json)
    fi
}

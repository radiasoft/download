#!/bin/bash

sirepo_dev_main() {
    if [[ ! -r /etc/redhat-release ]]; then
        install_err 'only works on Red Hat flavored Linux'
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant (or other ordinary user), not root'
    fi
    install_source_bashrc
    install_repo_eval beamsim-codes
    # rerun source, because beamsim-codes installs pyenv
    install_source_bashrc
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
    cd sirepo
    install_yum_install nodejs
    for p in jshint karma karma-jasmine karma-phantomjs-launcher jasmine-core; do
        if ! npm list "$p" >& /dev/null; then
           npm install "$p" >& /dev/null
        fi
    done
    cd ..
}

sirepo_dev_main ${install_extra_args[@]+"${install_extra_args[@]}"}

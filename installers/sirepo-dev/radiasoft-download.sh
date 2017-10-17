#!/bin/bash
#
# To run: curl radia.run | bash -s sirepo-dev
#
sirepo_dev_main() {
    if [[ ! -r /etc/redhat-release ]]; then
        install_err 'only works on Red Hat flavored Linux'
    fi
    if ! rpm -q tk-devel >& /dev/null; then
        # Need to sudo so can't use install_repo_eval
        curl radia.run | sudo bash -s redhat-base
    fi
    if [[ ! $(readlink ~/.bashrc) =~ home-env/dot ]]; then
        install_repo_eval home
        . ~/.bashrc
    fi
    if ! [[ $(type -t pyenv) && $(pyenv version-name) == py2 ]]; then
        bivio_pyenv_2
    fi
    . ~/.bashrc
    if ! rpm -q SDDSPython >& /dev/null; then
        install_repo_eval code common
    fi
    if ! type elegant >& /dev/null; then
        install_repo_eval code elegant
    fi
    if ! python -c 'import warp' >& /dev/null; then
        install_repo_eval code warp
    fi
    if ! python -c 'import srwlib' >& /dev/null; then
        install_repo_eval code srw
    fi
    if ! type rslinac >& /dev/null; then
        install_repo_eval code rslinac
    fi
    if ! python -c 'import Shadow' >& /dev/null; then
        install_repo_eval code shadow3
    fi
    if ! python -c 'import rsbeams' >& /dev/null; then
        install_repo_eval code rsbeams
    fi
    cd ~/src/radiasoft
    local p
    for p in pykern sirepo; do
        if [[ -d $p ]]; then
            continue
        fi
        pip uninstall -y "$p" >& /dev/null || true
        gcl "$p"
        cd "$p"
        pip install -r requirements.txt >& /dev/null
        pip install -e .
        cd ..
    done
}

sirepo_dev_main "${install_extra_args[@]}"

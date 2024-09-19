#!/bin/bash
#
# To run: curl radia.run | bash -s nersc-pyenv
#
nersc_pyenv_main() {
    if [[ $SHELL != /bin/bash ]]; then
        install_err "Currently only supports bash shells; SHELL=$SHELL"
    fi
    nersc_pyenv_vars
    declare r=$nersc_pyenv_root
    if [[ ! -d $r ]]; then
        # the path here avoids an error message
        curl -s -S -L https://pyenv.run | PATH="$r/bin:$PATH" bash
    fi
    if [[ ! -d $r/plugins/pyenv-virtualenv ]]; then
        git clone https://github.com/pyenv/pyenv-virtualenv.git "$r"/plugins/pyenv-virtualenv
    fi
    install_not_strict_cmd eval "$(pyenv init -)"
    install_not_strict_cmd eval "$(pyenv virtualenv-init -)"
    declare v=$install_version_python
    if [[ ! -e $r/versions/$v ]]; then
        PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install "$v"
    fi
    declare a=py3
    if [[ ! -e $r/versions/$a ]]; then
        pyenv virtualenv "$v" "$a"
    fi
    if ! ${nersc_pyenv_no_global:+}; then
        pyenv global "$a"
    fi
}

nersc_pyenv_vars() {
    if [[ ! ${nersc_pyenv_root:-} ]]; then
        install_err '$nerc_pyenv_root must be set'
    fi
}

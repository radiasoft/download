#!/bin/bash
#
# To run: curl radia.run | nersc_pyenv_root=~/.pyenv bash -s nersc-pyenv
#
nersc_pyenv_main() {
    if [[ $SHELL != /bin/bash ]]; then
        install_err "Currently only supports bash shells; SHELL=$SHELL"
    fi
    _nersc_pyenv_vars
    _nersc_pyenv_setup
    _nersc_pyenv_python
}

_nersc_pyenv_instructions() {
    if [[ ${nersc_pyenv_no_global:+} ]]; then
        # Not installing globally (nersc-sirepo-update sets this)
       return
    fi
    install_info "Add this to your ~/.bashrc:
export PYENV_ROOT=$PYENV_ROOT" '
if [[ ! $PATH =~ $PYENV_ROOT/bin ]]; then
    export PATH=$PYENV_ROOT/bin:$PATH
fi
if [[ $(type -f pyenv) != function ]]; then &> /dev/null; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi
'
}

_nersc_pyenv_python() {
    declare v=$install_version_python
    if [[ ! -e $PYENV_ROOT/versions/$v ]]; then
        PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install "$v"
    fi
    declare a=py3
    if [[ ! -e $PYENV_ROOT/versions/$a ]]; then
        pyenv virtualenv "$v" "$a"
    fi
    if ! ${nersc_pyenv_no_global:+}; then
        pyenv global "$a"
    fi
}

_nersc_pyenv_setup() {
    export PYENV_ROOT=$nersc_pyenv_root
    if [[ ! $PATH =~ $PYENV_ROOT/bin ]]; then
        export PATH="$PYENV_ROOT/bin:$PATH"
    fi
    if [[ ! -d $PYENV_ROOT ]]; then
        curl -s -S -L https://pyenv.run | bash
    fi
    if [[ ! -d $PYENV_ROOT/plugins/pyenv-virtualenv ]]; then
        git clone https://github.com/pyenv/pyenv-virtualenv.git "$PYENV_ROOT"/plugins/pyenv-virtualenv
    fi
    install_not_strict_cmd eval "$(pyenv init -)"
    install_not_strict_cmd eval "$(pyenv virtualenv-init -)"
}

_nersc_pyenv_vars() {
    if [[ ! ${nersc_pyenv_root:-} ]]; then
        install_err '$nerc_pyenv_root must be set'
    fi
}

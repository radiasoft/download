#!/bin/bash
#
# To run: curl radia.run | bash -s nersc-pyenv
#
nersc_pyenv_main() {
    local r=~/.pyenv
    if [[ ! -d $r ]]; then
        # the path here avoids an error message
        curl -s -S -L https://pyenv.run | PATH="$r/bin:$PATH" bash
    fi
    if [[ ! -d $r/plugins/pyenv-virtualenv ]]; then
        git clone https://github.com/pyenv/pyenv-virtualenv.git "$r"/plugins/pyenv-virtualenv
    fi
    if ! grep 'pyenv init' ~/.bashrc.ext; then
        perl -pi -e '/exiting .bashrc.ext/ && ($_ = q{
if ! [[ $PATH =~ pyenv/bin ]]; then
    export PYENV_ROOT='"$r"'
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"
fi
} . $_)' ~/.bashrc.ext
    fi
    install_source_bashrc
    local v='3.7.2'
    if [[ ! -e $r/versions/$v ]]; then
        PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install "$v"
    fi
    local a=py3
    if [[ ! -e $r/versions/$a ]]; then
        pyenv virtualenv "$v" "$a"
    fi
    pyenv global "$a"
}

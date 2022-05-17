#!/bin/bash
#
# To run: curl radia.run | bash -s nersc-pyenv
#
nersc_pyenv_main() {
    local r=~/.pyenv
    if [[ ! -d $r ]]; then
        curl -s -S -L https://pyenv.run | bash
    fi
    PATH="$r/bin:$PATH"
    eval "$(pyenv init --path)"
    if [[ ! -d $r/plugins/pyenv-virtualenv ]]; then
        git clone https://github.com/pyenv/pyenv-virtualenv.git "$r"/plugins/pyenv-virtualenv
    fi
    eval "$(pyenv virtualenv-init -)"
    local v='3.7.2'
    if [[ ! -e $r/versions/$v ]]; then
        PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install "$v"
    fi
    local a=py3
    if [[ ! -e $r/versions/$a ]]; then
        pyenv virtualenv "$v" "$a"
    fi
    pyenv global "$a"
    if ! grep 'pyenv init' ~/.bashrc.ext; then
        perl -pi -e '/exiting .bashrc.ext/ && ($_ = q{
if ! [[ $PATH =~ pyenv/bin ]]; then
    export PATH="~/.pyenv/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"
fi
} . $_)' ~/.bashrc.ext
    fi
}

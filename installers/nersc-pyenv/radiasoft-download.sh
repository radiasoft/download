#!/bin/bash
#
# To run: curl radia.run | bash -s nersc-pyenv
#
_nersc_pyenv_root=~/.pyenv

_nersc_pyenv_bashrc='
if ! [[ $PATH =~ pyenv/bin ]]; then
    export PYENV_ROOT='"$_nersc_pyenv_root"'
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"
fi
'

nersc_pyenv_bashrc() {
    local perl=$1
    local file=$2
    if ! grep 'pyenv init' "$file" >& /dev/null; then
        _nersc_pyenv_bashrc=$_nersc_pyenv_bashrc perl -pi.bak -e "$perl" "$file"
    fi
    install_source_bashrc
}

nersc_pyenv_main() {
    if [[ $SHELL != /bin/bash ]]; then
        install_err "Currently only supports bash shells; SHELL=$SHELL"
    fi
    local r=$_nersc_pyenv_root
    if [[ ! -d $r ]]; then
        # the path here avoids an error message
        curl -s -S -L https://pyenv.run | PATH="$r/bin:$PATH" bash
    fi
    if [[ ! -d $r/plugins/pyenv-virtualenv ]]; then
        git clone https://github.com/pyenv/pyenv-virtualenv.git "$r"/plugins/pyenv-virtualenv
    fi
    local p='
if ! [[ $PATH =~ pyenv/bin ]]; then
    export PYENV_ROOT='"$r"'
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"
fi
'
    if [[ -e ~/.bashrc.ext ]]; then
        nersc_pyenv_bashrc '/exiting .bashrc.ext/ && ($_ = $ENV{_nersc_pyenv_bashrc} . $_)' ~/.bashrc.ext
    else
        touch ~/.bashrc
        nersc_pyenv_bashrc 'END {print($ENV{_nersc_pyenv_bashrc})}' ~/.bashrc
    fi
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

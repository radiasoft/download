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
    local f=~/.bashrc.ext
    if [[ ! -e $f ]] || ! grep -i /.bashrc.ext ~/.bashrc; then
        f=~/.bashrc
    fi
    if ! grep 'pyenv init' "$f" >& /dev/null; then
        echo -n "$_nersc_pyenv_bashrc" >> "$f"
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
    nersc_pyenv_bashrc  ~/.bashrc.ext
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

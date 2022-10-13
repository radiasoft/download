#!/bin/bash

pyenv_homebrew() {
    # https://github.com/pyenv/pyenv/issues/1740#issuecomment-1020965784
    if [[ ! $(type -p brew) ]]; then
        install_repo_eval homebrew
        install_source_bashrc
    fi
    for p in readline bzip2 zlib openssl; do
        if ! brew list "$p" >& /dev/null; then
            brew install "$p"
        fi
    done
    export CFLAGS="-I$(brew --prefix openssl)/include -I$(brew --prefix bzip2)/include -I$(brew --prefix readline)/include -I$(xcrun --show-sdk-path)/usr/include"
    export LDFLAGS="-L$(brew --prefix openssl)/lib -L$(brew --prefix readline)/lib -L$(brew --prefix zlib)/lib -L$(brew --prefix bzip2)/lib"
}

pyenv_install() {
    # This line stops a warning from the pyenv installer
    bivio_path_insert "$PYENV_ROOT"/bin 1
    install_download https://pyenv.run | bash
    # Newer versions of patch do not like relative file names. Give this warning:
    # 'Ignoring potentially dangerous file name ../Python-2.7.8/Lib/site.py'
    # Updating the patches this way fixes the problem
    find "$PYENV_ROOT" -name \*.patch -print0 | xargs -0 -n 100 perl -pi -e 's{^(\+\+\+|--- |diff.* )\.\./}{$1}'
    install_source_bashrc
    if [[ $install_os_release_id == darwin ]]; then
        pyenv_homebrew
    fi
    export PYTHON_CONFIGURE_OPTS="${_pyenv_valgrind:+--without-pymalloc --with-pydebug --with-valgrind} --enable-shared"
    pyenv install "$install_version_python"
    pyenv global "$install_version_python"
    pip install --upgrade pip
    pip install --upgrade setuptools tox
    pyenv virtualenv "$install_version_python" "$install_version_python_venv"
    pyenv global "$install_version_python_venv"
}

pyenv_main() {
    declare x= _pyenv_valgrind=
    for x in "$@"; do
        case $x in
            valgrind)
                _pyenv_valgrind=1
                ;;
            *)
                install_err "unknown option=$x"
                ;;
        esac
    done
    if [[ ! $PYENV_ROOT ]]; then
        echo 'You must set PYENV_ROOT in bashrc before calling' 1>&2
        exit 1
    fi
    if [[ -d $PYENV_ROOT ]]; then
        install_err "pyenv already installed; PYENV_ROOT=$PYENV_ROOT exists"
    fi
    install_source_bashrc
    pyenv_install
}

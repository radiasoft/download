#!/bin/bash
#
# Update shifter image and pyenv
#
nersc_sirepo_update_main() {
    local c=${1:-}
    if [[ ! $c =~ ^(alpha|beta|prod)$ ]]; then
        install_err "invalid channel=${c:-<missing arg>}"
    fi
    if ! [[ $PATH =~ pyenv/bin ]]; then
        export PATH="$HOME/.pyenv/bin:$PATH"
    fi
    install_not_strict_cmd eval "$(pyenv init -)"
    install_not_strict_cmd eval "$(pyenv virtualenv-init -)"
    local i=docker:radiasoft/sirepo:$c
    shifterimg pull "$i"
    local v=sirepo-$c
    nersc_sirepo_update_pyenv "$v"
    install_not_strict_cmd pyenv shell "$virtualenv_name"
    local p x
    local d=~/"$v"/radiasoft
    mkdir -p "$d"
    cd "$d"
    for p in pykern sirepo; do
        if [[ ! -d "$p" ]]; then
            git clone https://github.com/radiasoft/"$p"
            cd "$p"
        else
            cd "$p"
            git checkout master
            git pull
        fi
        x=$(shifter --image="$i" /bin/bash -c "grep git-commit /home/vagrant/.pyenv/versions/py3/lib/python3*/site-packages/$p-20*-info/* 2>/dev/null")
        if [[ ! $x =~ git-commit=(.*) ]]; then
            install_err "missing git-commit for $p: output=$x"
        fi
        git checkout "${BASH_REMATCH[1]}"
        install_pip_uninstall .
        install_pip_install .
        cd ..
    done
    chmod 711 ~
    chmod -R a+rX ~/.pyenv
}

nersc_sirepo_update_pyenv() {
    virtualenv_name=$1
    if ! pyenv versions --bare | grep -q "^$install_version_python$"; then
        nersc_pyenv_no_global=1 install_repo_eval nersc-pyenv
    fi
    if [[ -e ~/.pyenv/versions/$virtualenv_name ]]; then
        install_not_strict_cmd pyenv shell "$virtualenv_name"
        if [[ $(python --version | cut -d' ' -f2) != $install_version_python ]]; then
            pyenv virtualenv-delete -f "$virtualenv_name"
        else
            return 0
        fi
    fi
    install_not_strict_cmd pyenv virtualenv "$install_version_python" "$virtualenv_name"
}

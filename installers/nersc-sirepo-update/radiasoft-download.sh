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
    if [[ ! -e ~/.pyenv/versions/$v ]]; then
        install_not_strict_cmd pyenv virtualenv "$RADIA_CI_VERSION_PYTHON" "$v"
    fi
    install_not_strict_cmd pyenv shell "$v"
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

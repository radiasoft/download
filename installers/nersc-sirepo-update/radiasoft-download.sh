#!/bin/bash
#
# Update shifter image and pyenv
#
nersc_sirepo_update_main() {
    local c=${1:-}
    if [[ ! $c =~ ^(alpha|beta|prod)$ ]]; then
        install_err "invalid channel=${c:-<missing arg>}"
    fi
    install_not_strict_cmd eval "$(pyenv init -)"
    install_not_strict_cmd eval "$(pyenv virtualenv-init -)"
    local i=docker:radiasoft/sirepo:$c
    shifterimg pull "$i"
    local v=sirepo-$c
    if [[ ! -e ~/.pyenv/versions/$v ]]; then
        pyenv virtualenv 3.7.2 "$v"
    fi
    pyenv shell "$v"
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
        x=$(shifter --image="$i" /bin/bash -c "grep git-commit /home/vagrant/.pyenv/versions/py3/lib/python3*/site-packages/$p-20*.dist-info/METADATA")
        if [[ ! $x =~ git-commit=(.*) ]]; then
            install_err "missing git-commit for $p: output=$x"
        fi
        git checkout "${BASH_REMATCH[1]}"
        pip uninstall -y . >& /dev/null || true
        pip install .
        cd ..
    done
    chmod 711 ~
    chmod -R a+rX ~/.pyenv
}

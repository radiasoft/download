#!/bin/bash
#
# Update/install sirepo shifter image, pyenv, python repos, and file
# permissions to be used by sirepo server in $channel.
#
# To test on nersc:
# export install_server=file://$HOME/src
# curl https://radia.run | install_debug=1 bash -s nersc-sirepo-update alpha
#
# In dev, add this (permanently):
# export nersc_sirepo_update_docker=1
#
nersc_sirepo_update_docker() {
    # For development
    declare cmd=$1
    declare image=$2
    declare args=( "${@:3}" )
    case $cmd in
        pull)
            docker pull "$image" | tee
            ;;
        run)
            docker run --net=none "$image" "${args[@]}"
            ;;
        *)
            install_err "invalid shifter command=$cmd"
            ;;
    esac
}

nersc_sirepo_update_main() {
    declare channel=${1:-}
    if [[ ! $channel =~ ^(alpha|beta|prod)$ ]]; then
        install_err "invalid channel=${channel:-<missing arg>}"
    fi
    declare v=sirepo-$channel
    nersc_sirepo_update_pyenv "$v"
    declare d=~/"$v"/radiasoft
    mkdir -p "$d"
    cd "$d"
    declare i=radiasoft/sirepo:$channel
    nersc_sirepo_update_shifter pull "$i"
    nersc_sirepo_update_python_repos "$i"
    # Needs to be world executable
    chmod 711 ~
    chmod -R a+rX ~/.pyenv
}

nersc_sirepo_update_pyenv() {
    declare venv_name=$1
    if [[ ! $PATH =~ pyenv/bin ]]; then
        export PATH="$HOME/.pyenv/bin:$PATH"
    fi
    if [[ ! -d ~/.pyenv ]]; then
        nersc_pyenv_no_global=1 install_repo_eval nersc-pyenv
    fi
    install_not_strict_cmd eval "$(pyenv init -)"
    install_not_strict_cmd eval "$(pyenv virtualenv-init -)"
    if ! pyenv versions --bare | grep -q "^$install_version_python$"; then
        nersc_pyenv_no_global=1 install_repo_eval nersc-pyenv
    fi
    if pyenv shell "$venv_name" 2>/dev/null \
        && [[ $(python --version | cut -d' ' -f2) == $install_version_python ]]; then
        return
    fi
    pyenv virtualenv-delete -f "$venv_name" &> /dev/null || true
    pyenv virtualenv "$install_version_python" "$venv_name"
    pyenv shell "$venv_name"
}

nersc_sirepo_update_python_repos() {
    declare image=$1
    declare p t
    for p in pykern sirepo; do
        t=$(nersc_sirepo_update_shifter run "$image" python -c "import $p; print($p.__version__)")
        if [[ ! $t =~ ^[0-9]{8}\.[0-9]{6}$ ]]; then
            install_err "package=$p missing version: output=$t"
        fi
        if [[ -d "$p" ]]; then
            cd "$p"
            git fetch --all --tags --prune
        else
            git clone https://github.com/radiasoft/"$p"
            cd "$p"
        fi
        git -c advice.detachedHead=false checkout -q tags/"$t"
        install_pip_install .
        cd ..
    done
}

nersc_sirepo_update_shifter() {
    if [[ ${nersc_sirepo_update_docker:+1} ]]; then
        nersc_sirepo_update_docker "$@"
        return
    fi
    declare cmd=$1
    declare image=docker:$2
    declare args=( "${@:3}" )
    case $cmd in
        pull)
            return
            shifterimg pull "$image" | tee
            ;;
        run)
            PYENV_VIRTUAL_ENV= PYENV_VIRTUALENV_INIT= PYENV_ROOT= PYENV_VERSION= shifter --image="$image" --entrypoint "${args[@]}"
            ;;
        *)
            install_err "invalid shifter command=$cmd"
            ;;
    esac
}

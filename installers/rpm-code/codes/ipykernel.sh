#!/bin/bash

ipykernel_main() {
    codes_dependencies common
    install_pip_install ipykernel
    # http://ipython.readthedocs.io/en/stable/install/kernel_install.html
    # http://www.alfredo.motta.name/create-isolated-jupyter-ipython-kernels-with-pyenv-and-virtualenv/
    local where=( $(ipykernel_install) )
    where=${where[-1]}
    if [[ ! $where  =~ ${codes_dir[share]} ]]; then
        install_err "expecting $where to be a subdirectory of ${codes_dir[share]}"
    fi
}

ipykernel_install() {
    local i=3
    local v=py$i
    local -a e=()
    for x in LD_LIBRARY_PATH PKG_CONFIG_PATH PYTHONPATH; do
        if [[ ${!x:-} ]]; then
            e+=" --env $x '${!x}'"
        fi
    done
    python -m ipykernel install \
        --display-name "Python $i" \
        --name "$v" \
        --user \
        --env PYENV_VERSION "$v" \
        ${e[@]}
}

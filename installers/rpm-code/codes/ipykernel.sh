#!/bin/bash

ipykernel_main() {
    codes_dependencies common
    install_pip_install ipykernel
}

ipykernel_python_install() {
    local -a e=()
    for x in LD_LIBRARY_PATH PKG_CONFIG_PATH PYTHONPATH; do
        if [[ ${!x:-} ]]; then
            e+=" --env $x ${!x}"
        fi
    done
    # http://ipython.readthedocs.io/en/stable/install/kernel_install.html
    # http://www.alfredo.motta.name/create-isolated-jupyter-ipython-kernels-with-pyenv-and-virtualenv/
    local -a l=$(python -m ipykernel install \
        --display-name "Python $1" \
        --name "$2" \
        --user \
        --env PYENV_VERSION "$2" \
        ${e[@]})
    l=${l[-1]}
    if [[ ! $l =~ ${codes_dir[share]} ]]; then
        install_err "expecting $l to be a subdirectory of ${codes_dir[share]}"
    fi
}

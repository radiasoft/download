#!/bin/bash

ipykernel_main() {
    codes_dependencies common
    install_pip_install ipykernel
}

ipykernel_python_install() {
    # http://ipython.readthedocs.io/en/stable/install/kernel_install.html
    # http://www.alfredo.motta.name/create-isolated-jupyter-ipython-kernels-with-pyenv-and-virtualenv/
    # TODO(e-carlin):  discuss w/ rjn $1 and $2 were removed in 341c73c3667396d2b18fdf2ac3f0d0a49ce1e7c2
    set -- '3' 'py3'

    local -a l=$(python -m ipykernel install \
        --display-name "Python $1" \
        --name "$2" \
        --user \
        --env PYENV_VERSION "$2")
    l=${l[-1]}
    if [[ ! $l =~ ${codes_dir[share]} ]]; then
        install_err "expecting $l to be a subdirectory of ${codes_dir[share]}"
    fi
}

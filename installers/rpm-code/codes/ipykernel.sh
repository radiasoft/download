#!/bin/bash

ipykernel_main() {
    codes_dependencies common
    install_pip_install ipykernel
}

ipykernel_python_install() {
    # http://ipython.readthedocs.io/en/stable/install/kernel_install.html
    # http://www.alfredo.motta.name/create-isolated-jupyter-ipython-kernels-with-pyenv-and-virtualenv/
    local -a l=$(python -m ipykernel install \
        --display-name "Python ${install_version_python%%.*}" \
        --name "$install_version_python_venv" \
        --user \
        --env PYENV_VERSION "$install_version_python_venv")
    l=${l[-1]}
    if [[ ! $l =~ ${codes_dir[share]} ]]; then
        install_err "expecting $l to be a subdirectory of ${codes_dir[share]}"
    fi
}

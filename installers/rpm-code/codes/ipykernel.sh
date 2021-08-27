#!/bin/bash

ipykernel_main() {
    codes_dependencies common
    install_pip_install ipykernel
    local i=3
    local v=py$i
    # http://ipython.readthedocs.io/en/stable/install/kernel_install.html
    # http://www.alfredo.motta.name/create-isolated-jupyter-ipython-kernels-with-pyenv-and-virtualenv/
    local where=( $(python -m ipykernel install --display-name "Python $i" --name "$v" --user) )
    where=${where[-1]}
    if [[ ! $where  =~ ${codes_dir[share]} ]]; then
        install_err "expecting $where to be a subdirectory of ${codes_dir[share]}"
    fi
    PYENV_VERSION=$v perl -pi -e '
        sub _e {
            return join(
                qq{,\n},
                map(
                    $ENV{$_} ? qq{  "$_": "$ENV{$_}"} : (),
                    qw(LD_LIBRARY_PATH PKG_CONFIG_PATH PYENV_VERSION PYTHONPATH),
                ),
            );
        }
        s/^\{/{\n "env": {\n@{[_e()]}\n },/
    ' "${where}"/kernel.json
}

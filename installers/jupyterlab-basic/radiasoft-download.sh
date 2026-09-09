#!/bin/bash
#
# Basic JupyterLab environment, shared by the jupyter container builds.
#
# Runs as the build run user. Callers install any rpms they need and add
# their own extras (julia/IJulia, widgets, matplotlib styles) themselves.
#
# To run: install_repo_eval jupyterlab-basic
#
jupyterlab_basic_main() {
    umask 022
    if [[ $(pyenv version-name) != py3 ]]; then
        install_err "environment is not right, missing pyenv: $(env)"
    fi
    _jupyterlab_basic_vars
    _jupyterlab_basic_pip
    _jupyterlab_basic_config
}

_jupyterlab_basic_config() {
    declare f
    install_tmp_dir
    for f in ipython_config.py jupyter_server_config.py post_bivio_bashrc radia-run.sh; do
        install_download "$f" > "$f"
    done
    python - <<'EOF' >> jupyter_server_config.py
from pykern import pkio
d = pkio.py_path("~/.local/share/jupyter/kernels/*/kernel.json")
s = set(x.dirpath().basename for x in pkio.sorted_glob(d))
assert s, f"could not find any kernels in dir={d}"
print(f"c.KernelSpecManager.allowed_kernelspecs = {s}\n")
EOF
    mkdir -p "$jupyterlab_basic_notebook_dir"
    for f in ~/.jupyter/jupyter_server_config.py ~/.ipython/profile_default/ipython_config.py; do
        mkdir -p "$(dirname "$f")"
        build_replace_vars "$(basename "$f")" "$f"
    done
    mkdir -p "$(dirname "$jupyterlab_basic_radia_run_boot")"
    build_replace_vars radia-run.sh "$jupyterlab_basic_radia_run_boot"
    chmod a+rx "$jupyterlab_basic_radia_run_boot"
    build_replace_vars post_bivio_bashrc ~/.post_bivio_bashrc
    install_source_bashrc
    # Removes the export TERM=dumb, which is incorrect for jupyter
    rm -f ~/.pre_bivio_bashrc
}

_jupyterlab_basic_pip() {
    if [[ ${jupyterlab_basic_pip[@]:+1} ]]; then
        install_pip_install "${jupyterlab_basic_pip[@]}"
        return
    fi
    # These lists were created by pip installing packages and seeing which
    # versions were installed. The "Successfully installed" line which pip outputs
    declare x=(

        # pip install jupyterlab
        'jupyterlab==4.5.1'
        'argon2-cffi==25.1.0'
        'argon2-cffi-bindings==25.1.0'
        'arrow==1.4.0'
        'async-lru==2.0.5'
        'beautifulsoup4==4.14.3'
        'bleach==6.3.0'
        'defusedxml==0.7.1'
        'fastjsonschema==2.21.2'
        'fqdn==1.5.1'
        'isoduration==20.11.0'
        'json5==0.12.1'
        'jsonpointer==3.0.0'
        'jupyter-events==0.12.0'
        'jupyter-lsp==2.3.0'
        'jupyter-server==2.17.0'
        'jupyter-server-terminals==0.5.3'
        'jupyterlab-pygments==0.3.0'
        'jupyterlab-server==2.28.0'
        'mistune==3.1.4'
        'nbclient==0.10.3'
        'nbconvert==7.16.6'
        'nbformat==5.10.4'
        'notebook-shim==0.2.4'
        'pandocfilters==1.5.1'
        'prometheus-client==0.23.1'
        'python-json-logger==4.0.0'
        'rfc3339-validator==0.1.4'
        'rfc3986-validator==0.1.1'
        'rfc3987-syntax==1.1.0'
        'send2trash==1.8.3'
        'soupsieve==2.8.1'
        'terminado==0.18.1'
        'tinycss2==1.4.0'
        'uri-template==1.3.0'
        'webcolors==25.10.0'
        'webencodings==0.5.1'
        'websocket-client==1.9.0'

        # pip install ipympl
        'ipympl==0.9.8'
        'ipywidgets==8.1.8'
        'jupyterlab_widgets==3.0.16'
        'widgetsnbextension==4.0.15'

        # pip install jupyter
        'jupyter==1.1.1'
        'jupyter-console==6.6.3'
        'notebook==7.5.1'

        # pip install jupyter-packaging
        'jupyter-packaging==0.12.3'
        'deprecation==2.1.0'
        'tomlkit==0.13.3'

        # Individual packages (not depending on each other)
        'jupyterlab-launcher==0.13.1'
        'jupyterlab-favorites==3.3.1'
        'plotly==6.5.0'

        # jupyterhub
        'jupyterhub==5.4.3'
        'Mako==1.3.10'
        'alembic==1.17.2'
        'certipy==0.2.2'
        'oauthlib==3.3.1'
        'pamela==1.2.0'
    )
    install_pip_install "${x[@]}"
}

_jupyterlab_basic_vars() {
    : ${jupyterlab_basic_init_from_git:=radiasoft/jupyter.radiasoft.org}
    : ${jupyterlab_basic_notebook_dir_base:=jupyter}
    jupyterlab_basic_boot_dir=$build_run_user_home/.radia-run
    jupyterlab_basic_notebook_dir=$build_run_user_home/$jupyterlab_basic_notebook_dir_base
    jupyterlab_basic_radia_run_boot=$jupyterlab_basic_boot_dir/start
    jupyterlab_basic_depot_server=$(install_depot_server)
    export jupyterlab_basic_depot_server
    export jupyterlab_basic_init_from_git
    export jupyterlab_basic_notebook_dir
}

#!/bin/bash
#
# Start juypterhub's single user init script with appropriate environment.
#
cd
source "$HOME"/.bashrc
if [[ -r $HOME/jupyter/pre_jupyter_bashrc ]]; then
    source "$HOME/jupyter/pre_jupyter_bashrc"
fi
if [[ '{jupyterlab_basic_init_from_git}' ]]; then
    curl {jupyterlab_basic_depot_server}/index.sh \
        | bash -s init-from-git '{jupyterlab_basic_init_from_git}'
fi
# must be after to avoid false returns in bashrc, init-from-git, and pyenv
set -e
cd '{jupyterlab_basic_notebook_dir}'
if [[ ${RADIA_RUN_CMD:-} ]]; then
    # Can't quote this, because environment var, not a bash array
    exec $RADIA_RUN_CMD
elif [[ ${JUPYTERHUB_API_URL:-} ]]; then
    # jupyterhub 0.9+
    # https://github.com/jupyter/docker-stacks/tree/master/base-notebook for
    # why this is started this way.
    # POSIT: 8888 in various jupyterhub repos
    exec jupyter labhub \
      --port="${RADIA_RUN_PORT:-8888}" \
      --ip=0.0.0.0 \
      --KernelManager.transport=ipc \
      --notebook-dir="$PWD"
else
    # Start jupyter lab possibly with radia-run supplied token
    # urandom never blocks and is good enough for this case
    p="${RADIA_RUN_PORT:-8888}"
    RADIA_RUN_CMD="jupyter lab --no-browser --port=$p --ip=0.0.0.0"
    #POSIT download/installers/container-run/radiasoft-download.sh
    t=$(cat .radia-run-jupyter-token 2>/dev/null || true)
    rm -f .radia-run-jupyter-token
    if [[ $t ]]; then
        echo "c.ServerApp.token = '$t'" >> $HOME/.jupyter/jupyter_server_config.py
        cat <<EOF
To connect to Jupyter, open:

http://127.0.0.1:$p/?token=$t

EOF
    fi
    exec $RADIA_RUN_CMD
fi

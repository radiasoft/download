#!/bin/bash
set +euo pipefail
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh
if ! radia_run rpm-code "$@"; then
    # this is a good guess, but there are other problems
    echo "you may need to start your server:

bash $PWD/dev-server.sh
"
    exit 1
fi
if [[ $1 == common ]]; then
    cd ~/src/radiasoft/container-rpm-code
    if [[ ! $(docker images | grep radiasoft/fedora) ]]; then
        cd container-fedora
        # in case set by dev-env.sh, because server isn't running yet
        radia_run container-build
    fi
    radia_run container-build
fi

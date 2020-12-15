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
    radia_run container-build
fi

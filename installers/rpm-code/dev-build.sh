#!/bin/bash
set +euo pipefail
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh

for r in container-rpm-code container-fedora; do
    if [[ ! -d ~/src/radiasoft/$r ]]; then
        echo "~/src/radiasoft/$r not found. You may need to run $PWD/dev-server.sh."
        exit 1
    fi
done

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
        cd ../container-fedora
        radia_run container-build
        cd -
    fi
    radia_run container-build
fi

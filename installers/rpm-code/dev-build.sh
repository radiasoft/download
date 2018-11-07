#!/bin/bash
set +euo pipefail
source ~/.bashrc
set -euo pipefail
. ./dev-env.sh
radia_run rpm-code "$@"
if [[ $1 == common ]]; then
    cd ~/src/radiasoft/container-rpm-code
    radia_run container-build
fi

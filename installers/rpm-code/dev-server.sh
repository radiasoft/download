#!/bin/bash
set -euo pipefail
source ./dev-env.sh
if [[ ! -e ~/src/yum/fedora/radiasoft.repo ]]; then
    echo 'setting up one time'
    bash dev-setup.sh
fi
cd ~/src
if [[ ! -r index.sh ]]; then
    ln -s -r radiasoft/download/bin/index.sh .
fi
exec python3 -m http.server "$dev_port"

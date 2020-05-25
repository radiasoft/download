#!/bin/bash
set -euo pipefail
source ./dev-env.sh
if [[ ! -e ~/src/yum/fedora/radiasoft.repo ]]; then
    echo 'setting up one time'
    bash dev-setup.sh
fi
cd ~/src
PYENV_VERSION=py3 exec pyenv exec python -m http.server "$dev_port"

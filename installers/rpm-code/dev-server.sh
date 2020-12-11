#!/bin/bash
set -euo pipefail
source ./dev-env.sh
if [[ ! -e $radiasoft_repo_file ]]; then
    echo 'setting up one time'
    bash dev-setup.sh
fi
cd ~/src
PYENV_VERSION=py3 exec pyenv exec python -m http.server "$dev_port"

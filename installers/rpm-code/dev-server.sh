#!/bin/bash
set -euo pipefail
source ./dev-env.sh
cd ~/src
PYENV_VERSION=py3 exec pyenv exec python -m http.server "$dev_port"

#!/bin/bash
set +euo pipefail
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh
radia_run beamsim-codes build ./dev-build.sh "${1:-}"

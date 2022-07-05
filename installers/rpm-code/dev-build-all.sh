#!/bin/bash
set +euo pipefail
source ~/.bashrc
set -euo pipefail
radia_run beamsim-codes build ./dev-build.sh "${1:-}"

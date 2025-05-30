#!/bin/bash
#
# Download all the codes from depot needed for beamsim
#
set +euo pipefail
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh
install_server= radia_run beamsim-codes build ./dnf-download.sh "${1:-}"

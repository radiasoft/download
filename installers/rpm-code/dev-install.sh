#!/bin/bash
. ~/.bashrc
set -euo pipefail
source ./dev-env.sh
radia_run code "$@"

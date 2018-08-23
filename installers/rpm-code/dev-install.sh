#!/bin/bash
. ~/.bashrc
set -euo pipefail
. ./dev-env.sh
radia_run code "$@"

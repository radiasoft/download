#!/bin/bash
. ~/.bashrc
set -euo pipefail
. ./dev-env.sh
export rpm_code_yum_dir=$(ls -d ~/src/yum/fedora/*/*/dev)
radia_run rpm-code "$@"

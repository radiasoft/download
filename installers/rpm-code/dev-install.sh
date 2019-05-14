#!/bin/bash
. ~/.bashrc
set -euo pipefail
source ./dev-env.sh
if ! cmp -s ~/src/yum/fedora/radiasoft.repo /etc/yum.repos.d/radiasoft.repo; then
    echo installing /etc/yum.repos.d/radiasoft.repo
    sudo install -m 644 ~/src/yum/fedora/radiasoft.repo /etc/yum.repos.d/radiasoft.repo
fi
radia_run code "$@"

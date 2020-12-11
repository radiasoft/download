#!/bin/bash
. ~/.bashrc
set -euo pipefail
source ./dev-env.sh
x=/etc/yum.repos.d/radiasoft.repo
if ! cmp -s $radiasoft_repo_file "$x"; then
    echo installing "$x"
    sudo install -m 644 "$radiasoft_repo_file" "$x"
fi
radia_run code "$@"

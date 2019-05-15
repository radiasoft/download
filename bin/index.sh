#!/bin/bash
#
# See https://github.com/radiasoft/download
#
set -e -o pipefail

index_main() {
    local u=https://raw.githubusercontent.com/radiasoft/download/master
    if [[ -n $install_server && $install_server != github ]]; then
        u=$install_server/radiasoft/download
    fi
    curl -s -S -L "$u/bin/install.sh?$(date +%s)" | bash -s "$@"
}

index_main "$@"

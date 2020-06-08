#!/bin/bash
#
# See https://github.com/radiasoft/download
#
set -e -o pipefail

index_main() {
    if [[ -n $install_server && $install_server != github ]]; then
        curl -s -S -L "$install_server/radiasoft/download/bin/install.sh?$(date +%s)" | bash ${install_debug:+-x} -s "$@"
    else
        curl -s -S -H 'Accept: application/vnd.github.raw' "https://api.github.com/repos/radiasoft/download/contents/bin/install.sh" | bash ${install_debug:+-x} -s "$@"
    fi
}

index_main "$@"

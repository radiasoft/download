#!/bin/bash
#
# See https://github.com/radiasoft/download
#
set -e -o pipefail

index_main() {
    local -a a=()
    if [[ -n $install_server && $install_server != github ]]; then
        a=( -L "$install_server/radiasoft/download/bin/install.sh" )
    else
        a=(
            -H 'Accept: application/vnd.github.raw'
            https://api.github.com/repos/radiasoft/download/contents/bin/install.sh
        )
    fi
    curl -s -S "${a[@]}" | bash ${install_debug:+-x} -s "$@"
}

index_main "$@"

#!/bin/bash
#
# See https://github.com/radiasoft/download
#
set -e -o pipefail

index_main() {
    declare -a a=()
    if [[ ${install_server:-} && $install_server != github ]]; then
        a=(
            --location
            "$install_server/radiasoft/download/bin/install.sh"
        )
    else
        if [[ ${GITHUB_TOKEN:-} ]]; then
            a+=( --header "Authorization: Bearer $GITHUB_TOKEN" )
        fi
        a+=(
            --header 'Accept: application/vnd.github.raw'
            https://api.github.com/repos/radiasoft/download/contents/bin/install.sh
        )
    fi
    curl --silent --show-error "${a[@]}" | bash ${install_debug:+-x} -s "$@"
}

index_main "$@"

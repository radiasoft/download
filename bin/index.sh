#!/bin/bash
#
# See https://github.com/radiasoft/download
#
set -euo pipefail
shopt -s nullglob

index_main() {
    declare -a a=()
    # POSIT: install.sh defaults to radia.run
    declare u=${install_server:-https://radia.run}
    if [[ $u == github ]]; then
        if [[ ${GITHUB_TOKEN:-} ]]; then
            a+=( --header "Authorization: Bearer $GITHUB_TOKEN" )
        fi
        a+=(
            --header 'Accept: application/vnd.github.raw'
            https://api.github.com/repos/radiasoft/download/contents/bin/install.sh
        )
    else
        a+=( "$u/radiasoft/download/bin/install.sh" )
    fi
    curl --fail --location --show-error --silent "${a[@]}" | install_server="$u" bash "${install_debug:+-x}" -s "$@"
}

index_main "$@"

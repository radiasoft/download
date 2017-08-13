#!/bin/bash
#
# To run: curl radia.run | bash -s centos7 op ...
#
centos7_install_file() {
    local file=$1
    local mode=$2
    local owner=$3
    local abs=/$file
    local d=$(dirname "$abs")
    if [[ ! -d $d ]]; then
        mkdir -p "$d"
    fi
    install_download "$file" > "$abs"
    if [[ -n $mode ]]; then
        chmod "$mode" "$abs"
    fi
    if [[ -n $owner ]]; then
        chown "$owner" "$abs"
    fi
}

centos7_main() {
    local op=$1
    shift
    local a=( "$@" )
    install_url radiasoft/centos7
    if [[ $op =~ / ]]; then
        install_err "$op: unknown operation"
    fi
    local f=$(basename "$op" .sh)
    install_script_eval "script/$f.sh"
    "${f//-/_}_main" "${a[@]}"
}

centos7_main "${install_extra_args[@]}"

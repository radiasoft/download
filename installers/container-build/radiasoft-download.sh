#!/bin/bash
#
# To run: curl radia.run | bash -s container-build
#
code_main() {
    local s=../containers/bin/build
    if [[ ! -x $s ]]; then
        local prev_d=$(pwd)
        install_tmp_dir
        git clone -b "$install_github_channel" -q https://github.com/radiasoft/containers
        s=$(pwd)/containers/$s
        cd "$prev_d"
    fi
    "$s" "${install_extra_args[@]}"
}

code_main

#!/bin/bash
#
# To run: curl radia.run | bash -s init-from-git repo...
#
# The file 'radia-run.sh' will be run in the cloned repo.
#
# repo may be https://github.com/foo/bar or foo/bar

init_from_git_main() {
    install_tmp_dir
    init_from_git_tmpdir=$(pwd)
    cd
    install_source_bashrc
    for repo in "${install_extra_args[@]}"; do
        init_from_git_one "$repo"
    done
}

init_from_git_one() {
    local repo=$1
    rm -rf "$init_from_git_tmpdir"
    mkdir -p "$init_from_git_tmpdir"
    (
        set -e
        cd "$init_from_git_tmpdir"
        if [[ ! repo =~ ^\w+:// ]]; then
            repo=https://github.com/$repo
        fi
        if SSH_ASKPASS=true git clone -q "$repo"; then
            cd "$(basename "$repo" .git)"
            . ./radia-run.sh
        fi
    ) || true
}

init_from_git_main

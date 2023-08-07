#!/bin/bash

container_sirepo_base_main() {
    declare user=${1:-}
    if [[ $user == root ]]; then
        container_sirepo_base_root
        return
    fi
    container_sirepo_base_run_user
}

container_sirepo_base_root() {
    build_yum install fedora-workstation-repositories
    build_yum config-manager --set-enabled google-chrome
    build_yum install google-chrome-stable
}

container_sirepo_base_run_user() {
    install_url radiasoft/sirepo
    #POSIT: This relies on the fact that individual package names don't have spaces or special chars
    npm install -g \
        $(install_download package.json | jq -r '.devDependencies | to_entries | map("\(.key)@\(.value)") | .[]')
}

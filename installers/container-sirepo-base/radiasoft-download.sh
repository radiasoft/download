#!/bin/bash
#
# Install dependencies common to containers for Sirepo development and CI.
#

container_sirepo_base_main() {
    declare user=$1
    case $user in
        root)
            container_sirepo_base_root
            ;;
        run_user)
            container_sirepo_base_run_user
            ;;
        *)
            install_err "user=$1 unknown. Please set 'root' or 'run_user'"
            ;;
    esac
}

container_sirepo_base_root() {
    build_yum install fedora-workstation-repositories
    build_yum config-manager --set-enabled google-chrome
    build_yum install google-chrome-stable
}

container_sirepo_base_run_user() {
    install_url radiasoft/sirepo
    install_source_bashrc
    #POSIT: This relies on the fact that individual package names don't have spaces or special chars
    npm install -g \
        $(install_download package.json | jq -r '.devDependencies | to_entries | map("\(.key)@\(.value)") | .[]')
}

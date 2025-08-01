#!/bin/bash
#
# To run: curl radia.run | bash -s code srw
#
code_main() {
    declare args=( "$@" )
    if [[ ! -e /etc/yum.repos.d/radiasoft.repo ]]; then
        #TODO(robnagler) always install from dev? Since we promote binaries, makes sense.
        install_yum_add_repo "$(install_depot_server)/yum/$install_os_release_id/$install_os_release_version_id/$(arch)/dev/radiasoft.repo"
    fi
    if [[ ! ${args:+1} ]]; then
        echo 'List of available codes:'
        declare f='%{name}'
        if [[ $(type -t dnf5) ]]; then
            f+='\n'
        fi
        install_yum repoquery --queryformat "$f" rscode-\* | perl -pe 's/^rscode-//'
        return 1
    fi
    declare rpms=()
    declare i
    for i in "${args[@]}"; do
        rpms+=( "rscode-$i" )
    done
    install_info "Installing: ${args[*]}"
    install_yum_install "${rpms[@]}"
}

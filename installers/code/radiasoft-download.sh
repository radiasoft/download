#!/bin/bash
#
# To run: curl radia.run | bash -s code warp
#
code_main() {
    local dnf=( dnf --color=never -y )
    if [[ ! -e /etc/yum.repos.d/radiasoft.repo ]]; then
        if ! rpm -q dnf-plugins-core >& /dev/null; then
            "${dnf[@]}" dnf-plugins-core
        fi
        #TODO(robnagler) always install from dev? Since we promote binaries, makes sense.
        install_sudo "${dnf[@]}" config-manager --add-repo "$(install_depot_server)/yum/$install_os_release_id/$install_os_release_version_id/$(arch)/dev/radiasoft.repo"
    fi
    if [[ ! ${install_extra_args:+1} ]]; then
        echo 'List of available codes:'
        "${dnf[@]}" repoquery --queryformat '%{NAME}' rscode-\* | perl -pe 's/^rscode-//'
        return 1
    fi
    local rpms=()
    local i
    for i in "${install_extra_args[@]}"; do
        rpms+=( "rscode-$i" )
    done
    install_info "Installing: ${install_extra_args[*]}"
    install_yum_install "${rpms[@]}"
}

code_main

#!/bin/bash
# intended to be sourced
cd "$(dirname "${BASH_SOURCE[0]}")"
_root() {
    local r=$PWD
    while [[ $(basename $r) != src ]]; do
        d=$(dirname "$r")
        if [[ $r == $d ]]; then
            echo "ERROR: could not find root: using $HOME/src" 1>&2
            echo "$HOME/src"
            return 1
        fi
        r=$d
    done
    echo "$r"
}
export dev_port=2916
export install_server=http://$(hostname -f):$dev_port
export fedora_version=36
export repo_fedora_dir=$(_root)/yum/fedora
export rpm_code_install_dir=$repo_fedora_dir/$fedora_version/$(arch)/dev
export radiasoft_repo_file=$repo_fedora_dir/radiasoft.repo
export install_proprietary_key=proprietary_code
# for convenience to test rpm-perl, not used here
export rpm_perl_install_dir=$(_root)/radiasoft/rsconf/rpm
unset _root

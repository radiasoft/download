#!/bin/bash
# intended to be sourced
cd "$(dirname "${BASH_SOURCE[0]}")"

_root() {
    declare r=$PWD
    declare d
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
export install_version_fedora=${install_version_fedora:-36}
export rpm_code_install_dir=$(_root)/yum/fedora/$install_version_fedora/$(arch)/dev
export radiasoft_repo_file=$rpm_code_install_dir/radiasoft.repo
export install_proprietary_key=proprietary_code
# for convenience to test rpm-perl, not used here
export rpm_perl_install_dir=$(_root)/radiasoft/rsconf/run/rpm
unset _root

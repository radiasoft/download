#!/bin/bash
# intended to be sourced
export dev_port=2916
export install_server=http://$(hostname -f):$dev_port
export fedora_version=32
export repo_rel_dir=fedora/$fedora_version/$(arch)/dev
export rpm_code_install_dir=$HOME/src/yum/$repo_rel_dir
export radiasoft_repo_file=$(dirname $(dirname $rpm_code_install_dir))/radiasoft.repo
export install_proprietary_key=proprietary_code
# for convenience to test rpm-perl, not used here
export rpm_perl_install_dir=$HOME/src/radiasoft/rsconf/rpm
cd "$(dirname "${BASH_SOURCE[0]}")"

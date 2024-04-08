#!/bin/bash
#
# Download rscode-*.rpm from system dnf repo
#
set -euo pipefail
declare code=$1
set +euo pipefail
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh
dnf download --downloaddir "$rpm_code_install_dir" "rscode-$code" || true
createrepo -q --update "$rpm_code_install_dir"
if [[ $code == common ]]; then
    cd ~/src/radiasoft/container-rpm-code
    if [[ ! $(docker images | grep radiasoft/fedora) ]]; then
        docker pull radiasoft/fedora
    fi
    # install_server should be set local server when building image
    radia_run container-build
fi

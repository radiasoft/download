#!/bin/bash
set +euo pipefail
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh
declare f
sudo dnf makecache
declare d=dnf-download-tmp
rm -rf "$d"
mkdir "$d"
declare common=0
for f in "$@"; do
    dnf download --downloaddir "$d" "rscode-$f"
    if [[ $1 == common ]]; then
        common=1
        cd ~/src/radiasoft/container-rpm-code
        if [[ ! $(docker images | grep radiasoft/fedora) ]]; then
            cd container-fedora
            # in case set by dev-env.sh, because server isn't running yet
            radia_run container-build
        fi
        radia_run container-build
    fi
done
mv "$d"/*.rpm "$rpm_code_install_dir"
createrepo -q --update "$rpm_code_install_dir"
if (( common )); then
    cd ~/src/radiasoft/container-rpm-code
    if [[ ! $(docker images | grep radiasoft/fedora) ]]; then
        cd container-fedora
        # in case set by dev-env.sh, because server isn't running yet
        radia_run container-build
    fi
    radia_run container-build
fi

#!/bin/bash
set -euo pipefail
source ./dev-env.sh
if ! rpm -q createrepo >& /dev/null; then
    sudo yum install -y createrepo
fi
if [[ ! -d $rpm_code_yum_dir ]]; then
    mkdir -p "$rpm_code_yum_dir"
    createrepo "$rpm_code_yum_dir"
fi
cat > ~/src/yum/fedora/radiasoft.repo <<EOF
[radiasoft-dev]
name=RadiaSoft fedora/29/x86_64 dev
baseurl=${install_server}/yum/fedora/\$releasever/\$basearch/dev
enabled=1
gpgcheck=0
# may be too fast for production
metadata_expire=1m
EOF
if [[ ! -d ~/src/radiasoft/container-rpm-code ]]; then
    (
        cd ~/src/radiasoft
        git clone https://github.com/radiasoft/container-rpm-code
    )
fi
if [[ ! -d ~/src/radiasoft/container-fedora ]]; then
    (
        set +euo pipefail
        source ~/.bashrc
        set -euo pipefail
        cd ~/src/radiasoft
        git clone https://github.com/radiasoft/container-fedora
        cd container-fedora
        radia_run container-build
    )
fi

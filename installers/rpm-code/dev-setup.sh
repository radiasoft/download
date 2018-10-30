#!/bin/bash
set -euo pipefail
. ./dev-env.sh
sudo yum install -y createrepo
mkdir -p "$rpm_code_yum_dir"
createrepo "$rpm_code_yum_dir"
cat > ~/src/yum/fedora/radiasoft.repo <<EOF
[radiasoft-dev]
name=RadiaSoft fedora/27/x86_64 dev
baseurl=${install_server}/yum/fedora/\$releasever/\$basearch/dev
enabled=1
gpgcheck=0
# may be too fast for production
metadata_expire=1m
EOF

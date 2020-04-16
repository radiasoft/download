#!/bin/bash
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh
# F29 has createrepo_c, but createrepo installs it
if [[ ! $(rpm -qa | grep createrepo) ]]; then
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
cd ~/src
if [[ ! -r index.sh ]]; then
    ln -s -r radiasoft/download/bin/index.sh .
fi
if [[ ! -r index.html ]]; then
    ln -s ~/src/radiasoft/download/bin/install.sh index.html
fi
cd radiasoft
for d in containers container-rpm-code container-fedora; do
    if [[ ! -d $d ]]; then
        git clone https://github.com/radiasoft/"$d"
    fi
done
if [[ ! $(type -p docker) ]]; then
    install_server= radia_run redhat-docker
fi
if [[ ! $(groups) =~ docker ]]; then
    echo 'you need to logout and log back in to get vagrant in the docker group'
    exit 1
fi
if [[ ! $(docker images | grep radiasoft/fedora) ]]; then
    cd container-fedora
    # in case set by dev-env.sh, because server isn't running yet
    install_server= radia_run container-build
fi

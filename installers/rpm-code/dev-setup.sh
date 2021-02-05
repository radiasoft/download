#!/bin/bash
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh
# Fedora has createrepo_c, but createrepo installs it
if [[ ! $(rpm -qa | grep createrepo) ]]; then
    sudo yum install -y createrepo
fi
if [[ ! -d $rpm_code_install_dir ]]; then
    mkdir -p "$rpm_code_install_dir"
    createrepo "$rpm_code_install_dir"
fi
cat > "$radiasoft_repo_file" <<EOF
[radiasoft-dev]
name=RadiaSoft $repo_rel_dir
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
if [[ ! -d $install_proprietary_key ]]; then
    mkdir -p "$install_proprietary_key"
fi
for f in CapLaserBELLA-4.6.2.tar.gz FLASH-4.6.2.tar.gz; do
    f=$install_proprietary_key/flash/$f
    if [[ ! -r $f ]]; then
        echo "For FLASH, install: $PWD/$f"
    fi
done
cd radiasoft
for d in containers container-rpm-code container-fedora; do
    if [[ ! -d $d ]]; then
        git clone https://github.com/radiasoft/"$d"
    fi
done
if [[ ! $(type -p docker) ]]; then
    if ! sudo su - -c 'radia_run redhat-docker'; then
        echo 'And rerun: bash dev-setup.sh' 1>&2
        exit 1
    fi
fi
if [[ ! $(groups) =~ docker ]]; then
    echo 'you need to logout and log back in to get vagrant in the docker group' 1>&2
    exit 1
fi

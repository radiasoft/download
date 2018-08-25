#!/bin/bash
set -euo pipefail
. ./dev-env.sh
rm -rf "$GNUPGHOME"
sudo yum install -y createrepo gnupg rpm-sign
install -d -m 700 "$GNUPGHOME"
gpg --batch --gen-key /dev/stdin <<EOF
Key-Type: rsa
Key-Length: 1024
Name-Real: RadiaSoft Fedora
Name-Email: support@radiasoft.net
Expire-Date: 0
%commit
%echo done
EOF
key_id=$(gpg --list-keys | perl -ne 'm{pub.*?/(\w+)} && print $1')
cat > "$GNUPGHOME"/.rpmmacros <<EOF
%_gpg_name $key_id
EOF
mkdir -p ~/src/yum/fedora/27/x86_64/dev
createrepo ~/src/yum/fedora/27/x86_64/dev
gpg --export -a > ~/src/yum/fedora/gpg
cat > ~/src/yum/fedora/radiasoft.repo <<EOF
[radiasoft-dev]
name=RadiaSoft fedora/27/x86_64 dev
baseurl=${install_server}/yum/fedora/\$releasever/\$basearch/dev
enabled=1
gpgcheck=1
gpgkey=${install_server}/yum/fedora/gpg
# may be too fast for production
metadata_expire=1m
EOF

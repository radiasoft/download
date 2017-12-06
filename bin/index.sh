#!/bin/bash
#
# See https://github.com/radiasoft/download
#
set -e -o pipefail
_u=https://raw.githubusercontent.com/radiasoft/download/master
if [[ -n $install_server && $install_server != github ]]; then
    _u=$install_server/radiasoft/download
fi
curl -s -S -L "$_u/bin/install.sh" | bash -s "$@"

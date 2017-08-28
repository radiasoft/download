#!/bin/bash
#
# See https://github.com/radiasoft/download
#
set -e -o pipefail
curl -s -S -L \
    "https://raw.githubusercontent.com/radiasoft/download/master/bin/install.sh" \
    | bash -s "$@"

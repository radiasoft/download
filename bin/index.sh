#!/bin/bash
#
# See https://github.com/radiasoft/download
#
: ${download_channel:=master}
set -e -o pipefail
curl -s -S -L \
    "https://raw.githubusercontent.com/radiasoft/download/$download_channel/bin/install.sh" \
    | download_channel="$download_channel" bash -s "$@"

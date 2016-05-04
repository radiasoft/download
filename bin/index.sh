#!/bin/bash
#
# Usage: curl radiasoft.download | bash -s [repo | [vagrant|docker] <container>]
#
: ${download_channel:=master}
curl -s -S -L \
    "https://raw.githubusercontent.com/radiasoft/download/$download_channel/bin/install.sh" \
    | download_channel="$download_channel" bash -s "$@"

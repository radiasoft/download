#!/bin/bash
#
# Usage: curl radiasoft.download | bash -s [vagrant|docker] <container>
#
curl -s -S -L \
    https://raw.githubusercontent.com/radiasoft/download/master/bin/install.sh \
    | bash -s "$@"

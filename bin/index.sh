#!/bin/bash
#
# Static file returned to start install from http://radiasoft.download
#
curl -s -S -L \
    https://raw.githubusercontent.com/radiasoft/download/master/bin/install.sh \
    | bash -s "$@"

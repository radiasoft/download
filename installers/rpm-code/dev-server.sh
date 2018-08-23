#!/bin/bash
set -euo pipefail
if [[ ! -d gnupg.d ]]; then
    echo 'setting up one time: this will take hours, possibly'
    bash dev-setup.sh
fi
cd ~/src
if [[ ! -r index.sh ]]; then
    ln -s -r radiasoft/download/bin/index.sh .
fi
python -m SimpleHTTPServer "$dev_port"

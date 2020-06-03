#!/bin/bash
set +euo pipefail
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh
if [[ $1 == flash ]]; then
    export rpm_code_install_dir=$HOME/src/radiasoft/rsconf/rpm
    export rpm_code_is_proprietary=1
    if [[ ! -d $rpm_code_install_dir ]]; then
        echo 'you need to setup rsconf:

cd ~/src/radiasoft
gcl rsconf
cd rsconf
rsconf build
'
        exit 1
    fi
    d=$HOME/src/$install_proprietary_key/flash
    if [[ ! -d $d ]]; then
        echo "you need to get the flash source and put it here:

cd $d
curl -O -L <source-url>
"
    fi
fi
if ! radia_run rpm-code "$@"; then
    # this is a good guess, but there are other problems
    echo "you may need to start your server:

bash $PWD/dev-server.sh
"
    exit 1
fi
if [[ $1 == common ]]; then
    cd ~/src/radiasoft/container-rpm-code
    radia_run container-build
fi

#!/bin/bash
set +euo pipefail
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh

for r in container-rpm-code container-fedora; do
    if [[ ! -d ~/src/radiasoft/$r ]]; then
        echo "~/src/radiasoft/$r not found. You may need to run $PWD/dev-server.sh."
        exit 1
    fi
done

if [[ $1 == common ]]; then
    if [[ ! $(docker images | grep radiasoft/fedora) ]]; then
        cd ~/src/radiasoft/container-fedora
        radia_run container-build
        cd -
    fi
else
    declare i=rpm-code
    declare m='You need to dev-build.sh common'
    if [[ $1 =~ -nvidia$ ]]; then
        i=rpm-code-nvidia
        m='You need to build radiasoft/container-rpm-code-nvidia'
    fi
    export required_image="radiasoft/$i:fedora-$install_version_fedora"
    set +e
    docker image inspect $required_image > /dev/null
    if [[ $? -ne 0 ]]; then
        echo "$required_image image not found. $m"
        exit 1
    fi
    set -e
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

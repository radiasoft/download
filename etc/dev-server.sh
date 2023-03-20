#!/bin/bash
set -eou pipefail
cd ~/src
declare host=${1:-}
declare index_sh=radiasoft/download/bin/index.sh
if [[ ! -r $index_sh ]]; then
    echo "Expect $PWD/$index_sh to exist, see README.md"
    exit 1
fi
declare f
for f in index.html index.sh; do
    if [[ $(readlink "$f") != $index_sh ]]; then
        rm -f "$f"
        ln -s "$index_sh" "$f"
    fi
done
if [[ ! $host ]]; then
    host=$(dig $(hostname -f || true) +short || true)
    if [[ ! $host && $(type -p ipconfig) ]]; then
        host=$(ipconfig getifaddr en0)
    fi
    if [[ ! $host ]]; then
        cat <<EOF
Unable to determine ip address of this host. Supply on command line:
bash $0 ipaddr
EOF
        exit 1
    fi
fi
declare p=2916
declare install_server=http://$host:$p
cat <<EOF
In another shell, set the install_server:
export install_server=$install_server

Then run with function:
radia_run unit-test arg1

or

curl $install_server | bash -s unit-test arg1

You can also pass "debug" to get more output:
radia_run debug unit-test arg1

For persistent debugging, set:
export install_debug=1

EOF
exec python3 -m http.server "$p"

#!/bin/bash
#
# To run: curl radia.run | bash -s code warp
#
code_assert_args() {
    if ! python -c 'import requests' >& /dev/null; then
        if ! type pip >& /dev/null; then
            return
        fi
        pip install requests
    fi
    if ! python - "$@" <<EOF 2>&1; then
import requests, sys

uri = 'https://api.github.com/repos/radiasoft/download/contents/installers/code/codes?ref=$install_github_channel'
r = requests.get(uri)
r.raise_for_status()
have = [n[:-3] for n in map(lambda x: x['name'], r.json()) if n.endswith('.sh')]
want = sys.argv[1:]
msg = []
if want:
    miss = set(want).difference(set(have))
    if not miss:
        sys.exit(0)
    msg.append('Code(s) not found: ' + ', '.join(miss))
msg += ['List of available codes:'] + have
sys.stderr.write('\n'.join(msg) + '\n')
sys.exit(1)
EOF
        install_err "usage: $install_prog code <code-name...>"
    fi
}

code_install() {
    local codes=( "$@" )
    install_tmp_dir
    local url=https://github.com
    if [[ -n $install_server && $install_server != github ]]; then
        url=$install_server
    fi
    if [[ $url =~ ^file://(.+) ]]; then
        cp -a "${BASH_REMATCH[1]}/radiasoft/download" download
    else
        git clone -b "$install_github_channel" -q "$url/radiasoft/download"
    fi
    cd download/installers/code
    codes_debug=$codes_debug codes_dir=$(pwd)/codes \
        bash -l ${install_debug:+-x} codes.sh "${codes[@]}"
}

code_main() {
    local args=( "${install_extra_args[@]}" )
    : ${codes_debug:=}
    if [[ ${args[0]:-} == debug ]]; then
        codes_debug=1
        args=( "${args[@]:1}" )
    fi
    code_assert_args "${args[@]}"
    code_install "${args[@]}"
}

code_main

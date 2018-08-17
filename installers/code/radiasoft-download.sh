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
import requests, sys, os

uri = 'https://api.github.com/repos/radiasoft/download/contents/installers/code/codes?ref=$install_github_channel'
r = requests.get(uri)
r.raise_for_status()
have = [n[:-3] for n in map(lambda x: x['name'], r.json()) if n.endswith('.sh')]
want = sys.argv[1:]
msg = []
if want:
    miss = set(want).difference(set(have))
    # could check to see if code is there if install_server set
    if not miss or os.getenv('install_server'):
        sys.exit(0)
    msg.append('Code(s) not found: ' + ', '.join(miss))
msg += ['List of available codes:'] + have
sys.stderr.write('\n'.join(msg) + '\n')
sys.exit(1)
EOF
        install_err "usage: $install_prog code <code-name...>"
    fi
}

code_main() {
    local args=( ${install_extra_args[@]+"${install_extra_args[@]}"} )
    : ${codes_debug:=}
    if [[ ${args[0]:-} == debug ]]; then
        codes_debug=1
        args=( "${args[@]:1}" )
    fi
    code_assert_args "${args[@]}"
    install_url radiasoft/download installers/code
    install_script_eval codes.sh "${args[@]}"
}

code_main

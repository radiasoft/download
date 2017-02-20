#!/bin/bash
#
# To run: curl radia.run | bash -s code warp
#
code_assert_args() {
    if ! python -c 'import requests' >& /dev/null; then
        # environment missing core components (radiasoft/python2)
        # so can't validate args. Happens with
        # radiasoft/download/travis.sh
        return
    fi
    if ! python - "$@" <<EOF 2>&1; then
import requests, sys
uri = 'https://api.github.com/repos/radiasoft/container-beamsim/contents/container-conf/codes?ref=$install_github_channel'
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
    install_tmp_dir
    git clone -b "$install_github_channel" -q https://github.com/radiasoft/container-beamsim
    cd container-beamsim/container-conf
    bash -l codes.sh "$@"
}

code_main() {
    code_assert_args "${install_extra_args[@]}"
    code_install "${install_extra_args[@]}"
}

code_main

#!/bin/bash
codes_dependencies common

synergia_bootstrap() {
    local fnal=http://cdcvs.fnal.gov/projects
    # "git clone --depth 1" doesn't work in some case
    #     fatal: dumb http transport does not support --depth
    # so if you don't pass a commit to codes_download, you'll see this error.
    codes_download  http://bitbucket.org/fnalacceleratormodeling/contract-synergia2.git origin/devel
    ./bootstrap
}

synergia_contractor() {
    # Turn off parallel make
    local f
    local -a x=()
    local cores=$(codes_num_cores)
    codes_msg "Using cores=$cores"
    for f in bison chef-libs fftw3 freeglut libpng nlopt qutexmlrpc qwt synergia2; do
        x+=( "$f"/make_use_custom_parallel=1 "$f"/make_custom_parallel="$cores")
    done
    for f in bison fftw3 libpng nlopt; do
        x+=( "$f"_internal=1 )
    done
    x+=(
        #NOT in master: boost/parallel="$cores"
        #chef-libs/repo=https://github.com/radiasoft/accelerator-modeling-chef.git
        #chef-libs/branch=5277ecbbdec02e9394eca4e079a651053b6a0ab4
        #chef-libs/branch=radiasoft-devel
    )
    if [[ ${codes_synergia_branch:-} ]]; then
        x+=( synergia2/branch=$codes_synergia_branch )
        if [[ $codes_synergia_branch == devel-pre3 ]]; then
            x+=( boost_internal=1 )
        fi
    fi
    ./contract.py --configure "${x[@]}"
    ./contract.py
}

synergia_install() {
    # openmpi should be added automatically (/etc/ld.so.conf.d), but there's
    # a conflict with hdf5, which has same library name in /usr/lib64 as in
    # /usr/lib64/openmpi/lib.
    perl -pi -e '
        s{(?<=install_dir/lib)}{/synergia};
        s{(?=ldpathadd ")}{ldpathadd /usr/lib64/openmpi/lib\n}s;
    ' install/bin/synergia
    local d=$(pyenv prefix)
    # Synergia installer doesn't set modes correctly in all cases
    chmod -R a+rX install
    (
        set -euo pipefail
        cd install
        cp -a bin include "$d"
        local l="$d/lib/synergia"
        mv lib "$l"
        local p="$l"/python2.7/site-packages
        mv "$p"/* "$l"
        # sanity check to make sure directory is empty
        rmdir "$p" "$(dirname "$p")"
    )
    return $?
}

synergia_pyenv_exec() {
    local f=~/.pyenv/pyenv.d/exec/rs-beamsim-synergia.bash
    perl -p -e "s{PREFIX}{$(pyenv prefix)}" <<'EOF' > "$f"
#!/bin/bash
#
# Synergia needs these special paths to work.
#
if [[ PREFIX == $(pyenv prefix) ]]; then
    # only set if in the environment we built synergia; prevents "jupyter" environment
    # from screwing this up.
    export SYNERGIA2DIR=PREFIX/lib/synergia
    export LD_LIBRARY_PATH=$SYNERGIA2DIR:/usr/lib64/openmpi/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    export PYTHONPATH=$SYNERGIA2DIR
fi
EOF
    rpm_code_build_include_add "$f"
    rpm_code_build_exclude_add "$(dirname "$f")"
}

synergia_main() {
    synergia_bootstrap
    synergia_contractor
    synergia_install
    synergia_pyenv_exec
    synergia_version
}

synergia_version() {
    local d
    for d in chef-libs synergia2; do
        (
            set -euo pipefail
            cd build/"$d"
            codes_manifest_add_code
        )
    done
}

synergia_main

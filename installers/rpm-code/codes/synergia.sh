#!/bin/bash
codes_dependencies common

synergia_bootstrap() {
    # "git clone --depth 1" doesn't work in some case
    #     fatal: dumb http transport does not support --depth
    # so if you don't pass a commit to codes_download, you'll see this error.
    codes_download https://bitbucket.org/fnalacceleratormodeling/contract-synergia2.git origin/devel
    ./bootstrap
}

synergia_contractor() {
    local cores=$(codes_num_cores)
    codes_msg "Using default_parallel=$cores"
    local -a x=(
        default_parallel=$cores
        #TODO(robnagler) Need to figure out how to patch synergia2 itself
        # before the build but after contractor downloads it.
        synergia2/repo=https://bitbucket.org/robnagler/synergia2
    )
    local f
    # chef_libs gets random make errors when running parallel
    for f in chef-libs; do
        x+=( "$f"/make_use_custom_parallel=1 "$f"/make_custom_parallel=1 )
    done
    for f in bison fftw3 libpng nlopt; do
        x+=( "$f"_internal=1 )
    done
    ./contract.py --configure "${x[@]}"
    ./contract.py
}

synergia_install() {
    # mpi should be added automatically (/etc/ld.so.conf.d), but there's
    # a conflict with hdf5, which has same library name in /usr/lib64 as in
    # $BIVIO_MPI_PREFIX/lib.
    perl -pi -e '
        s{(?<=install_dir/lib)}{/synergia};
        s{(?=ldpathadd ")}{ldpathadd '"$BIVIO_MPI_PREFIX"'/lib\n}s;
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
    local p=$(pyenv prefix)
    if [[ $p =~ : ]]; then
        install_err "Invalid pyenv prefix, has a colon: $p"
    fi
    perl -p -e "s{PYENV_PREFIX}{$p};s{BIVIO_MPI_PREFIX}{$BIVIO_MPI_PREFIX}" <<'EOF' > "$f"
#!/bin/bash
#
# Synergia needs these special paths to work.
#
if [[ :$(pyenv prefix): =~ :PYENV_PREFIX: ]]; then
    # only set if in the environment we built synergia; prevents "jupyter" environment
    # from screwing this up.
    export SYNERGIA2DIR=PYENV_PREFIX/lib/synergia
    for i in $BIVIO_MPI_PREFIX/lib "$SYNERGIA2DIR"; do
        if [[ ! :$LD_LIBRARY_PATH: =~ :$i: ]]; then
            export LD_LIBRARY_PATH=$i${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
        fi
    done
    unset i
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

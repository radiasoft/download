#!/bin/bash
elegant_build() {
    local make=(
        make
        -j$(codes_num_cores)
        COMMANDLINE_LIBRARY=
        EPICS_HOST_ARCH=linux-x86_64
        HOME=$HOME
        LINKER_USE_RPATH=NO
    )
    local make_static=( "${make[@]}" SHARED_LIBRARIES=NO )
    local make_x11=( "${make_static[@]}" MOTIF_LIB=/usr/lib64 X11_LIB=/usr/lib64 )
    local make_mpi=( "${make_static[@]}" MPI=1 MPI_PATH=$(dirname $(type -p mpicc))/ )
    local h=$PWD
    cd epics/base
    local base=$PWD
    "${make[@]}"
    cd "$h"/epics/extensions/configure
    "${make[@]}"
    cd "$h"/oag/apps/configure
    echo EPICS_BASE=$base >> RELEASE
    echo CROSS_COMPILER_TARGET_ARCHS= >> CONFIG
    "${make[@]}"
    cd "$h"/epics/extensions/src/SDDS
    "${make_x11[@]}"
    cd "$h"/oag/apps/src/utils/tools
    "${make_x11[@]}"
    cd "$h"/epics/extensions/src/SDDS/python
    "${make[@]}"
    codes_install_add_python
    install -m 644 "$h"/epics/extensions/src/SDDS/python/sdds.py "$so" "$d"

    "$h"/epics/extensions/lib/linux-x86_64/sddsdatamodule.so
}

elegant_download() {
    local f
    for f in '' /apps /apps/configure /apps/configure/os /apps/config /apps/src/utils/tools; do
        svn --non-recursive -q checkout https://svn.aps.anl.gov/AOP/oag/trunk"$f" oag"$f"
    done
    local u=https://ops.aps.anl.gov/downloads/
    for f in elegant.2019.1.1 SDDS.4.1 epics.base.configure epics.extensions.configure; do
        u=https://ops.aps.anl.gov/downloads/$f.tar.gz
        if [[ $f =~ ^(.+[[:alpha:]])\.([[:digit:]].+)$ ]]; then
            codes_manifest_add_code "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$u"
        fi
        codes_curl "$u" | tar xzf -
    done
}

elegant_main() {
    codes_dependencies common
    codes_yum_dependencies subversion openmotif-devel motif-devel libXaw-devel libXt-devel libXp-devel tcsh
    elegant_share
    elegant_download
    elegant_build
}

elegant_share() {
    local share_d=$(codes_dir_share)/elegant
    install -d -m 755 "$share_d"
    local f d
    for f in defns.rpn LICENSE; do
        codes_download_module_file "$f"
        d=$share_d/$f
        install -m 444 "$f" "$d"
    done
    rpm_code_build_include_add "$share_d"
    f=$(codes_dir_bashrc_d)/rscode-elegant.sh
    cat > "$f" <<EOF
#!/bin/bash
export RPN_DEFNS=$share_d/defns.rpn
EOF
    rpm_code_build_include_add "$f"
}

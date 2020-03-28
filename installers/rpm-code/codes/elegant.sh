#!/bin/bash

_elegant_arch=linux-x86_64

elegant_build() {
    local h=$PWD
    local with_path="PATH=$h/epics/extensions/bin/$_elegant_arch:$PATH"
    cd epics/base
    local base=$PWD
    elegant_make shared
    cd "$h"/epics/extensions/configure
    elegant_make shared
    cd "$h"/oag/apps/configure
    echo EPICS_BASE=$base >> RELEASE
    echo CROSS_COMPILER_TARGET_ARCHS= >> CONFIG
    elegant_make shared
    cd "$h"/epics/extensions/src/SDDS
    # builds ./epics/extensions/bin/linux-x86_64/bin/*
    # epics/extensions/lib/linux-x86_64/libSDDS1.a (plus other *.a)
    elegant_make x11
    cd "$h"/oag/apps/src/utils/tools
    elegant_make x11
    # Do not install any of the tools (token, mecho, minpath, etc.)
    local to_exclude=( $(find * -executable -type f -printf '%f\n') )
    cd "$h"/oag/apps/src/physics
    elegant_make static
    cd ../xraylib
    elegant_make static
    cd ../elegant
    elegant_make static "$with_path"
    cd elegantTools
    elegant_make static "$with_path"
    cd ../sddsbrightness
    elegant_make static
    cd "$h"/epics/extensions/src/SDDS/SDDSlib
    elegant_make clean
    # builds epics/extensions/lib/linux-x86_64/libSDDSmpi.a
    elegant_make mpi
    cd ../pgapack
    elegant_make mpi
    cd ../../../../../oag/apps/src/elegant
    elegant_make clean
    elegant_make mpi "$with_path" Pelegant
    # Not installing things like:
    # ./oag/apps/src/physics/spectraCLITemplates
    # ./oag/apps/src/elegant/ringAnalysisTemplates
    # ./oag/apps/src/elegant/elegantTools/*.lte
    #
    # Some epics/extensions/src/SDDS/SDDSaps are not in the sdds or elegant rpm
    # but we install them anyway (e.g. sdds2stl, col2sdds) since they don't collide
    cd "$h"
    local f b
    local dst=${codes_dir[bin]}
    for f in {oag/apps,epics/extensions}/bin/linux-x86_64/*; do
        b=$(basename "$f")
        if [[ ! " ${to_exclude[*]} " =~ " $b " ]]; then
            install -m 555 "$f" "$dst"
        fi
    done
}

elegant_download() {
    local f
    for f in '' /apps /apps/configure /apps/configure/os /apps/config /apps/src/utils/tools; do
        svn --non-recursive -q checkout https://svn.aps.anl.gov/AOP/oag/trunk"$f" oag"$f"
    done
    local u=https://ops.aps.anl.gov/downloads/
    for f in elegant.2019.3.0 SDDS.4.1 epics.base.configure epics.extensions.configure; do
        u=https://ops.aps.anl.gov/downloads/$f.tar.gz
        if [[ $f =~ ^(.+[[:alpha:]])\.([[:digit:]].+)$ ]]; then
            codes_manifest_add_code "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$u"
        fi
        codes_curl "$u" | tar xzf -
    done
}

elegant_main() {
    codes_yum_dependencies \
        lapack-devel \
        libXaw-devel \
        libXp-devel \
        libXt-devel \
        motif-devel \
        openmotif-devel \
        subversion \
        tcsh
    codes_dependencies common
    elegant_download
    elegant_build
    elegant_share
}

elegant_make() {
    local mode=$1
    shift
    local shared=(
        codes_make
        COMMANDLINE_LIBRARY=
        EPICS_HOST_ARCH=$_elegant_arch
        HOME=$HOME
        LINKER_USE_RPATH=NO
    )
    local static=( "${shared[@]}" SHARED_LIBRARIES=NO )
    case $mode in
        clean)
            "${shared[@]}" clean
            ;;
        mpi)
            "${static[@]}" MPI=1 MPI_PATH=$(dirname $(type -p mpicc))/ "$@"
            ;;
        shared)
            "${shared[@]}" "$@"
            ;;
        static)
            "${static[@]}" "$@"
            ;;
        x11)
            "${static[@]}" MOTIF_LIB=/usr/lib64 X11_LIB=/usr/lib64 "$@"
            ;;
        *)
            codes_err "unknown mode=$mode; must be clean, mpi, shared, static, x11"
            ;;
    esac
}

elegant_python_install() {
    local v=$1
    local h=$PWD
    cd epics/extensions/src/SDDS/python
    elegant_make clean
    # builds extensions/lib/linux-x86_64/sddsdatamodule.so
    local p3=
    if (( v >= 3 )); then
        p3=PYTHON3=1
        # PYTHON_PREFIX is incorrectly configured in the Makefile. Should
        # use get_python_inc to get the directory. This fix is good enough.
        # https://github.com/radiasoft/download/issues/83
        local p=$(python3 -c 'import distutils.sysconfig as s; from os.path import dirname as d; print(d(d(s.get_python_inc())))')
        perl -pi -e 's{^(PYTHON_PREFIX\s*=\s*).*python3.*}{$1 '"$p"'}' Makefile
    fi
    # PYTHON3 is ifdef'd so will be empty (no arg) when not py3
    elegant_make shared $p3
    # py3 builds sddsdata.so; py2 builds sddsdatamodule.so
    codes_python_lib_copy "$h"/epics/extensions/src/SDDS/python/sdds.py \
        "$h"/epics/extensions/lib/linux-x86_64/sddsdata*.so
    # remove just for in case sddsdata gets renamed
    rm -f "$h"/epics/extensions/lib/linux-x86_64/sddsdata*.so
}

elegant_share() {
    local share_d=${codes_dir[share]}/elegant
    install -d -m 755 "$share_d"
    local f d
    for f in defns.rpn LICENSE; do
        codes_download_module_file "$f"
        d=$share_d/$f
        install -m 444 "$f" "$d"
    done
    f=${codes_dir[bashrc_d]}/rscode-elegant.sh
    cat > "$f" <<EOF
#!/bin/bash
export RPN_DEFNS=$share_d/defns.rpn
EOF
}

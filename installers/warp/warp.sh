#!/bin/bash
#
# Setup execution environment for warp based on script's location
# Build warp if not built, and add to path
#

if [ -z "$BASH" ]; then
    echo 'This script only works with bash'
    return 1
    exit 1
fi

_radia_warp_build() {
    if [[ -d $_radia_warp_python ]]; then
        _radia_warp_msg "Using existing build in $_radia_warp_root"
        return
    fi
    rm -rf "$_radia_warp_tmp" "$_radia_warp_root"
    mkdir "$_radia_warp_tmp"
    cd "$_radia_warp_tmp"
    local knl=
    if [[ -n $_radia_warp_knl ]]; then
        knl=' for KNL'
    fi
    _radia_warp_msg "Building WARP with PICSAR$knl in $_radia_warp_msg"
    # Only thing that requires privs
    if ! git clone https://bitbucket.org/berkeleylab/picsar.git; then
        _radia_warp_msg 'You need access to the picsar repo'
        return 1
    fi
    git clone https://github.com/dpgrote/Forthon.git
    cd Forthon
    python setup.py install --home="$_radia_warp_root"
    cd ..
    git clone https://bitbucket.org/berkeleylab/warp.git
    cd warp/pywarp90
    cat > Makefile.local.pympi <<EOF
FCOMP = -F gfortran --fcompexec ftn --fargs -fPIC --cargs -fPIC
INSTALLOPTIONS = --home='$_radia_warp_root'
EOF
    make pinstall
    cd ../../picsar
    perl -p -e 's/(?<=^FCOMPEXEC=)/ftn/; s/(?<=^LIBS=)/-lgomp/' \
        Makefile_Forthon.in > Makefile_Forthon
    if [[ -n $_radia_warp_knl ]]; then
        perl -pi -e 's/(?<=^FARGS=")/-march=knl /' Makefile_Forthon
    fi
    make -f Makefile_Forthon all
    cp -a python_module/picsar_python "$_radia_warp_python"
    cd ..
}

_radia_warp_dirs() {
    local warp_bin=$_radia_warp_root/bin
    _radia_warp_tmp=$_radia_warp_root/tmp
    rm -rf "$_radia_warp_tmp"
    mkdir -p "$_radia_warp_tmp"
    _radia_warp_python=$_radia_warp_root/lib/python
    local p=:$PATH
    if [[ ! ":$PATH:" =~ :$warp_bin: ]]; then
        export "PATH=$warp_bin:$PATH"
    fi
    if [[ ! ":$PYTHONPATH:" =~ :$radia_warp_python: ]]; then
        export "PYTHONPATH=$warp_python:$PYTHONPATH"
    fi
}

_radia_warp_knl() {
    _radia_warp_knl=
    if [[ $NERSC_HOST == cori ]]; then
        _radia_warp_knl=1
    fi
}

_radia_warp_main() {
    _radia_warp_root=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)/warp
    if [[ $0 == ${BASH_SOURCE[0]} ]]; then
        _radia_warp_msg "You need to source this file. Execute:
    source ${BASH_SOURCE[0]}
    "
        return 1
    fi
    _radia_warp_knl
    _radia_warp_modules
    _radia_warp_dirs
    (
        set -e
        _radia_warp_build
        rm -rf "$_radia_warp_tmp"
    )
    if (( $? != 0 )); then
        _radia_warp_msg "WARP-PICSAR build FAILED.
Files are in $_radia_warp_tmp"
        return 1
    fi
    _radia_warp_msg 'WARP-PICSAR setup complete'
}

_radia_warp_modules() {
    local modules=" $(module list 2>&1 | perl -n -e 'm{(\S+/\S+)} && print qq{$1 }')"
    local -a ops
    if [[ $modules =~ ' PrgEnv-intel/' ]]; then
        module swap PrgEnv-intel PrgEnv-gnu
    fi
    if [[ ! $module =~ ' h5py-parallel/' ]]; then
        module load h5py-parallel
    fi
    if [[ ! $module =~ ' python/2.7-anaconda ' ]]; then
        module load python/2.7-anaconda
    fi
}

_radia_warp_msg() {
    echo "$@" 1>&2
}

_radia_warp_unset() {
    local x
    for x in $(compgen -A variable _radia_warp); do
        unset -v "$x"
    done
    for x in $(compgen -A 'function' _radia_warp); do
        unset -f "$x"
    done
}

_radia_warp_main

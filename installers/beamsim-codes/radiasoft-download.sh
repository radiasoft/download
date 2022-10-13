#!/bin/bash

declare -a _beamsim_codes_all=(
    common

    # a simple one first
    genesis

    # libraries
    pydot
    boost
    ml

    rsbeams

    amrex

    # create a delay here so radiasoft.repo in radiasoft/rpm-code
    # is "old" by the time bnlcrl (or other fast build) happens
    # otherwise, the cache will be stale
    synergia

    jspec

    bnlcrl
    # depends on ml
    srw
    radia

    ipykernel
    bluesky

    elegant

    epics

    hypre

    h5hut
    parmetis
    metis
    trilinos
# see pyopaltools.sh
#    pyopaltools
    opal

    madx
    mantid
    openmc

    # needs hypre and metis
    petsc
    slepc
    fenics

    mgis

    pydicom

    pymesh

    forthon
    openpmd
    pygist
    warp

    xraylib
    shadow3

    pyzgoubi
    zgoubi

)

# Some of these are deps and others are just build deps.
# If something is missed from this list, it will get installed,
# which is probably no harm done. trilinos is the big one to not install.
declare -a _beamsim_codes_install_skip=(
    pydot
    boost
    fnl_chef
    h5hut
    parmetis
    metis
    trilinos
    petsc
    slepc
    forthon
    openpmd
    pygist
    xraylib
    pyzgoubi
)

beamsim_codes_build() {
    local script=$1
    local start_at=${2:-}
    for c in "${_beamsim_codes_all[@]}"; do
        if [[ $start_at ]]; then
            if [[ $start_at != $c ]]; then
                continue
            fi
            start_at=
        fi
        echo "$c"
        bash "$script" "$c"
    done
}

beamsim_codes_install() {
    # Ensure everything is up to date first
    # If there are codes already installed, they'll update common,
    # etc. first, which may be required for later codes.
    install_yum update
    # POSIT: codes do not have special or spaces
    install_repo_eval code $(beamsim_codes_install_list)
    install_repo_eval fedora-patches
}

beamsim_codes_install_list() {
    local IFS='|'
    local r='^('"${_beamsim_codes_install_skip[*]}"')$'
    local c
    for c in "${_beamsim_codes_all[@]}"; do
        if [[ ! $c =~ $r ]]; then
            echo "$c"
        fi
    done

}

beamsim_codes_main() {
    local build=${1:-}
    if [[ $build == build ]]; then
        shift
        beamsim_codes_build "$@"
        return
    fi
    beamsim_codes_install
}

#!/bin/bash
#
# Usage for install:
#
# radia_run beamsim-codes [codes...]
#
# Without args, installs "everything" (see list below and _beamsim_codes_install_skip).
# Otherwise installs only specific codes listed in args.
#
# Usage for build:
# radia_run beamsim-codes build build-script.sh [start_at]
#
# Tries to build all codes with build-script.sh. If start_at is set,
# will skip codes until start_at found and then builds that and the
# rest of the codes.

declare -a _beamsim_codes_all=(
    common

    # a simple one first
    genesis

    # libraries
    boost
    pydot
    ml
    rsbeams

    # Jupyter utility
    ndiff

    # Sirepo codes
    # create a delay here so radiasoft.repo in radiasoft/rpm-code
    # is "old" by the time bnlcrl (or other fast build) happens
    # otherwise, the cache will be stale
    elegant

    bnlcrl
    # depends on ml
    srw
    radia

    h5hut
    parmetis
    hypre
    trilinos
    opal

    openpmdapi
    pydicom
    impactt

    # Depends on genesis and lume-base installed by impactt
    genesis4

    # depends on openpmdapi
    amrex
    pyamrex
    warpx
    # depends on warpx
    impactx

    madx

    openmc
    cadopenmc

    # Also needs hypre and metis
    petsc
    slepc
    fenics

    warp

    xraylib
    bmad
    shadow3


    # Other codes
    epics
    epics-asyn
    epics-pvxs

    # Deps of container-beamsim-jupyter-base
    geant4
    julia
    madness

    # Codes not installed
    # aravis
    # It's needed by pymesh, maybe, but not installed currently.
    # cgal
    # NOTE: mantid requires ipykernel so add that back into common
    # and lock version same as jupyter-base and add a note there, too
    # mantid ipykernel==??
    # mlopal
    # requires boost python and unused
    # mgis
    # rshellweg
    # pyzgoubi
    # zgoubi
    # jspec
)

# Some of these are deps, others are just build deps, and others are
# deps of jupyter.
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
    pyzgoubi

    # Deps of container-beamsim-jupyter-base
    geant4
    julia
    madness
)

beamsim_codes_build() {
    declare script=$1
    declare start_at=${2:-}
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

beamsim_codes_init_vars() {
    if install_version_fedora_lt_36; then
        _beamsim_codes_all+=('synergia')
    fi
}

beamsim_codes_install() {
    # POSIT: codes do not have special or spaces
    install_repo_eval code ${*:-$(beamsim_codes_install_list)}
    install_repo_eval fedora-patches
}

beamsim_codes_install_list() {
    declare IFS='|'
    declare r='^('"${_beamsim_codes_install_skip[*]}"')$'
    declare c
    for c in "${_beamsim_codes_all[@]}"; do
        if [[ ! $c =~ $r ]]; then
            echo "$c"
        fi
    done

}

beamsim_codes_main() {
    beamsim_codes_init_vars
    declare build=${1:-}
    if [[ $build == build ]]; then
        shift
        beamsim_codes_build "$@"
        return
    fi
    beamsim_codes_install "$@"
}

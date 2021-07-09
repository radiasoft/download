#!/bin/bash
set -euo pipefail
start_at=${1:-}
codes=(
    common

    # a simple one first
    genesis

    # libraries
    pydot
    boost
    ml

    rsbeams

    # create a delay here so radiasoft.repo in radiasoft/rpm-code
    # is "old" by the time bnlcrl (or other fast build) happens
    # otherwise, the cache will be stale
    fnal_chef
    synergia

    jspec

    bnlcrl
    # depends on ml
    srw
    radia

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

    # needs hypre and metis
    petsc
    slepc
    petsc4py
    slepc4py
    fenics

    pydicom

    pymesh

    forthon
    openpmd
    pygist
    warp

    libgfortran4
    xraylib
    shadow3

    pyzgoubi
    zgoubi

)
for c in "${codes[@]}"; do
    if [[ $start_at ]]; then
        if [[ $start_at != $c ]]; then
            continue
        fi
        start_at=
    fi
    echo "$c"
    bash ./dev-build.sh "$c"
done

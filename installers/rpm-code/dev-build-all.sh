#!/bin/bash
set -euo pipefail
start_at=${1:-}
codes=(
    common

    # some simple ones first
    genesis
    rsbeams

    # libraries
    pydot
    boost

    # create a delay here so radiasoft.repo in radiasoft/rpm-code
    # is "old" by the time bnlcrl (or other fast build) happens
    # otherwise, the cache will be stale
    fnal_chef
    synergia

    jspec

    bnlcrl
    srw
    radia

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

    ml_for_py3

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

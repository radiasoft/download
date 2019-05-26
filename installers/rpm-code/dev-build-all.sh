#!/bin/bash
set -euo pipefail
codes=(
    common

    # create a delay here so radiasoft.repo in radiasoft/rpm-code
    # is "old" by the time bnlcrl (or other fast build) happens
    # otherwise, the cache will be stale
    synergia

    jspec

    bnlcrl
    srw
    radia

    elegant

    epics

    hypre

    H5hut
    parmetis
    metis
    trilinos
    pyOPALTools
    opal

    pydicom

    pymesh

    Forthon
    openPMD
    pygist
    warp

    xraylib
    shadow3

    rsbeams

    zgoubi
)
for c in "${codes[@]}"; do
    echo "$c"
    bash ./dev-build.sh "$c"
done

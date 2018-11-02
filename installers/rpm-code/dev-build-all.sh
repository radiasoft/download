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

    sdds
    elegant

    H5hut
    parmetis
    metis
    trilinos
    pyOPALTools
    opal

    Forthon
    openPMD
    pygist
    warp

    rslinac

    xraylib
    shadow3

    rsbeams
)
for c in "${codes[@]}"; do
    echo "$c"
    bash ./dev-build.sh "$c"
done

#!/bin/bash
set -euo pipefail
start_at=${1:-}
codes=(
#    common

    # some simple ones first
#    rsbeams

#    genesis

    # create a delay here so radiasoft.repo in radiasoft/rpm-code
    # is "old" by the time bnlcrl (or other fast build) happens
    # otherwise, the cache will be stale
#    synergia

#    jspec

#    bnlcrl
#    srw
#    radia

#    elegant

#    epics
#
#    hypre

#    H5hut
#    parmetis
#    metis
#    trilinos
# not in use
#    pyOPALTools
    opal

    pydicom

    pymesh

    Forthon
    openPMD
    pygist
    warp

    libgfortran4
    xraylib
    shadow3

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

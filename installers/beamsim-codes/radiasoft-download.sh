#!/bin/bash

beamsim_codes_main() {
    # Ensure everything is up to date first
    # If there are codes already installed, they'll update common,
    # etc. first, which may be required for later codes.
    install_yum update
    local codes=(
        # include common here even though a dependency so
        # that the latest gets installed without bloating
        # the container with an update (below). By default
        # only the version that's required by the other packages
        # gets installed.
        common

        bluesky
        elegant
        epics
        fenics
        genesis
        ipykernel
        jspec
        hypre
        madx
        ml
        opal
        openmc
        pydicom
        pymesh
        rsbeams
        shadow3
        srw
        # depends on srw
        radia
        synergia
        warp
        zgoubi

    )
    # if [[ ! ${sirepo_dev_codes_only:-} ]]; then
    #     codes+=()
    # fi
    install_repo_eval code "${codes[@]}"
    install_repo_eval fedora-patches
}

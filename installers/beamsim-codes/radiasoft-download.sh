#!/bin/bash

beamsim_codes_main() {
    local codes=(
        # include common here even though a dependency so
        # that the latest gets installed without bloating
        # the container with an update (below). By default
        # only the version that's required by the other packages
        # gets installed.
        common

        elegant
        jspec
        opal
        rsbeams
        rslinac
        shadow3
        srw
        synergia
        warp
        zgoubi

        # depends on srw
        radia
    )
    install_repo_eval code "${codes[@]}"
    # Ensure everything is up to date
    install_yum update
}

beamsim_codes_main ${install_extra_args[@]+"${install_extra_args[@]}"}

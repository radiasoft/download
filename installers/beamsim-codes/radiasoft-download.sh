#!/bin/bash

beamsim_codes_main() {
    local codes=(
        elegant
        jspec
        opal
        rsbeams
        rslinac
        shadow3
        srw
        synergia
        warp
    )
    install_repo_eval code "${codes[@]}"
}

beamsim_codes_main "${install_extra_args[@]}"

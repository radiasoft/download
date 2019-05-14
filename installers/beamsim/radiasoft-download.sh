#!/bin/bash
#
# To run: curl radia.run | bash -s beamsim
#
beamsim_main() {
    install_repo_eval container-run beamsim "$@"
}

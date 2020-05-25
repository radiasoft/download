#!/bin/bash
#
# To run: curl radia.run | bash -s sirepo
#
sirepo_main() {
    install_repo_eval container-run sirepo "$@"
}

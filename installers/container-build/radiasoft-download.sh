#!/bin/bash
#
# To run: curl radia.run | bash -s container-build
#
container_build_main() {
    install_repo_eval radiasoft/containers "$@"
}

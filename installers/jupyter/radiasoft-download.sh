#!/bin/bash
#
# To run: curl radia.run | bash -s jupyter
#
jupyter_main() {
    install_repo_eval container-run jupyter "$@"
}

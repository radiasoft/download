#!/bin/bash
#
# To run: curl radia.run | bash -s home
#
home_main() {
    install_url biviosoftware/home-env
    eval "$(install_download install.sh)"
}

home_main

#!/bin/bash
#
# To run: curl radia.run | bash -s home
#
home_main() {
    install_url biviosoftware/home-env
    install_script_eval install.sh
}

home_main

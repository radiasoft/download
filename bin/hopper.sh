#!/bin/bash
#
# Download installer and execute
#
hopper_main() {
    install_info "Installing $install_image on $install_type"
    eval "$(install_download "$install_type-$install_image.sh")"
}

hopper_main "$@"

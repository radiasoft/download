#!/bin/bash

fedora_patches_mpich() {
    if grep -s -q format-security /usr/lib64/mpich/bin/mpifort; then
        # mpif77 and mpif90 are symlinks
        install_sudo perl -pi -e 's{(?=-Werror=format-security)}' /usr/lib64/mpich/bin/mpifort
    fi
    if ! grep -s -q -- '-Wformat' /usr/lib64/mpich/bin/mpic{c,xx}; then
        perl -pi.dist -e 's{(?=-Werror=format-security)}{-Wformat }'/usr/lib64/mpich/bin/mpic{c,xx}
    fi
}

fedora_patches_main() {
    fedora_patches_mpich
}

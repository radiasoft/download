#!/bin/bash

fedora_patches_mpich() {
    # don't eliminate this, because this puts cmake in an infinite
    # loop trying to find mpicc when building opal. For some
    # reason opal needs to set CC=mpicc and CXX=mpicxx
    # s{-specs=/usr/lib/rpm/redhat/redhat-hardened-cc1}{}g;

    # to read the recorded switches:
    # readelf -p .GCC.command.line a.out

    install_sudo perl -pi -w -e '
    s{-Wp,-D_FORTIFY_SOURCE=2}{}g;
    s{-Wp,-D_GLIBCXX_ASSERTIONS}{}g;
    s{-fplugin=annobin}{}g;
    s{-fstack-clash-protection}{}g;
    s{-fstack-protector-strong}{}g;
    # this does not turn on symbols (-g)
    s{-g(?=record-gcc-switches)}{-f}g;
    s{-fcf-protection}{}g;
    s{-specs=/usr/lib/rpm/redhat/redhat-annobin-cc1}{}g;
    # these flags are supplied by make/cmake
    s{-O2}{}g;
    s{-g\b}{}g;
    ' /usr/lib64/mpich/bin/mpifort /usr/lib64/mpich/bin/mpic{c,xx}
    if grep -s -q format-security /usr/lib64/mpich/bin/mpifort; then
        # mpif77 and mpif90 are symlinks
        install_sudo perl -pi -w -e 's{-Werror=format-security}{}g' /usr/lib64/mpich/bin/mpifort
    fi
    if ! grep -s -q -- '-Wformat' /usr/lib64/mpich/bin/mpic{c,xx}; then
        install_sudo perl -pi -w -e 's{(?=-Werror=format-security)}{-Wformat };s{}{};' /usr/lib64/mpich/bin/mpic{c,xx}
    fi
}

fedora_patches_main() {
    fedora_patches_mpich
}

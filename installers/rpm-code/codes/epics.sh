#!/bin/bash

_epics_version=7.0.8

epics_install() {
    declare b="${codes_dir[prefix]}"/epics
    codes_download https://epics.anl.gov/download/base/base-"$_epics_version".tar.gz
    cd ..
    mv base-"$_epics_version" "$b"
    cd "$b"
    epics_pcas
    declare a=linux-x86_64
    codes_make \
         EPICS_HOST_ARCH="$a" \
         LINKER_USE_RPATH=YES \
         SHARED_LIBRARIES=YES
    # Needs to happen here to get access to files in $b
    EPICS_BASE="$b" EPICS_HOST_ARCH="$a" install_pip_install  pcaspy
    # leave bin because there are other files (.pl & .pm) that may be referenced
    # Some of these are large, e.g. modules
    rm -rf modules documentation html src test
    find lib -name '*.a' | xargs -n 100 rm -f
    cd bin/"$a"
    ls | egrep -v '^S99|\.p[lm]$' | xargs -I % install -m 555 % "${codes_dir[bin]}"
}

epics_main() {
    codes_yum_dependencies swig
    codes_dependencies common
    epics_install
}

epics_pcas() {
    declare p="$PWD"
    mkdir modules/pcas
    cd $_
    codes_curl https://github.com/epics-modules/pcas/archive/refs/tags/v4.13.3.tar.gz \
        | tar xzf - --strip-components=1
    cd ..
    cat > Makefile.local <<'EOF'
SUBMODULES += pcas
pcas_DEPEND_DIRS = libcom
EOF
    cd "$p"
}

epics_python_install() {
    install_pip_install p4p
}

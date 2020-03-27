#!/bin/bash

epics_main() {
    codes_dependencies common
    codes_download https://epics.anl.gov/download/base/base-7.0.2.tar.gz
    cd ..
    mv base-7.0.2 "$HOME"/.local/epics
    cd "$HOME"/.local/epics
    local arch=linux-x86_64
    codes_make \
         EPICS_HOST_ARCH="$arch" \
         LINKER_USE_RPATH=YES \
         SHARED_LIBRARIES=YES
    # leave bin because there are other files (.pl & .pm) that may be referenced
    # Some of these are large, e.g. modules
    rm -rf modules documentation html src test
    find lib -name '*.a' | xargs -n 100 rm -f
    cd bin/"$arch"
    ls | egrep -v '^S99|\.p[lm]$' | xargs -I % install -m 555 % "${codes_dir[bin]}"
}

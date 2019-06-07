#!/bin/bash

epics_main() {
    codes_dependencies common
    codes_download https://epics.anl.gov/download/base/base-7.0.2.tar.gz
    local arch=linux-x86_64
    make -j"$(codes_num_cores)" \
         EPICS_HOST_ARCH="$arch" \
         HOME="$HOME" \
         LINKER_USE_RPATH=NO \
         SHARED_LIBRARIES=NO
    cd bin/"$arch"
    ls | egrep -v '^S99|\.pl$' | xargs -I % install -m 555 % "${codes_dir[bin]}"
}

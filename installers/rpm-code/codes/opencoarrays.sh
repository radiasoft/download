#!/bin/bash

opencoarrays_main() {
    codes_dependencies common
    codes_download sourceryinstitute/OpenCoarrays
    codes_cmake -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make install
}

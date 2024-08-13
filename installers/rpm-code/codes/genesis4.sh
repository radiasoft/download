#!/bin/bash
#
# Genesis Version4 was a re-write of Version3. Many things (ex input
# file format) changed in a backwards incompatible way. So, we are
# going to install Version3 (genesis.sh) and Version4 (gensis4.sh)
# side-by-side until we can fix the breakage.
#

genesis4_main() {
    codes_dependencies common
    codes_download https://github.com/svenreiche/Genesis-1.3-Version4.git
    codes_cmake
    codes_make all
    install -m 555 genesis4 "${codes_dir[bin]}"/genesis4
}

#!/bin/bash

taucmdr_main() {
    codes_dependencies common
    codes_download ParaToolsInc/taucmdr unstable
    i=$HOME/.local/taucmdr
    codes_make_install TAU=full USE_MINICONDA=false INSTALLDIR="$i"
}

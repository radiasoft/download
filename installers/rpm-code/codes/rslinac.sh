#!/bin/bash

rslinac_main() {
    codes_dependencies common boost
    codes_download radiasoft/rslinac beamsim_build
}

rslinac_python_install() {
    cd rslinac
    CFLAGS=-I${codes_dir[include]} codes_python_install
}

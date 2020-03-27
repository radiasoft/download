#!/bin/bash

rslinac_main() {
    codes_dependencies common
    codes_download radiasoft/rslinac beamsim_build
}

rslinac_python_install() {
    cd rslinac
    codes_python_install
}

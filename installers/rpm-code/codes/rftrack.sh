#!/bin/bash

rftrack_main() {
    codes_dependencies common
    codes_download radiasoft/rslume
}

rftrack_python_install() {
    install_pip_install RF-Track==2.7.3
    # rslume depends on sirepo
    cd rslume
    codes_python_install --no-deps
}

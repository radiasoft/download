#!/bin/bash

rftrack_main() {
    codes_dependencies common
    codes_download https://github.com/lume-science/lume-rftrack.git
}

rftrack_python_install() {
    install_pip_install RF-Track==2.7.3
    cd lume-rftrack
    codes_python_install
}

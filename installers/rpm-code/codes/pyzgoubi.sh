#!/bin/bash

pyzgoubi_python_install() {
    install_pip_install zgoubi_metadata
    cd PyZgoubi
    codes_python_install
}

pyzgoubi_main() {
    codes_dependencies common
    codes_download https://github.com/PyZgoubi/PyZgoubi.git
}

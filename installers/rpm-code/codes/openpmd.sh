#!/bin/bash

openpmd_main() {
    codes_dependencies common
}

openpmd_python_install() {
    install_pip_install openPMD-viewer
}

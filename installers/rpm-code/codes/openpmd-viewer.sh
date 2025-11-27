#!/bin/bash

openpmd_viewer_main() {
    codes_dependencies common
}

openpmd_viewer_python_install() {
    install_pip_install openPMD-viewer
}

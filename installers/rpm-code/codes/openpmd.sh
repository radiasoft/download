#!/bin/bash

openpmd_main() {
    codes_dependencies common
}

openpmd_python_install() {
    pip install openPMD-viewer
}

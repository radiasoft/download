#!/bin/bash
shadow3_main() {
    codes_dependencies xraylib libgfortran4
    shadow3_python_versions=3
}

shadow3_python_install() {
    pip install srxraylib shadow3
}

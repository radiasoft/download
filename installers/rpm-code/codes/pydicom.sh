#!/bin/bash

pydicom_python_install() {
    install_pip_install dicompyler-core pydicom
}

pydicom_main() {
    codes_dependencies common
}

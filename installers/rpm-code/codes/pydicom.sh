#!/bin/bash

pydicom_python_install() {
    install_pip_install dicompyler-core==0.5.6 pydicom==3.0.1
}

pydicom_main() {
    codes_dependencies common
}

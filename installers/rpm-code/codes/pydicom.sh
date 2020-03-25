#!/bin/bash
pydicom_python_install() {
    pip install dicompyler-core==0.5.4 pydicom==1.0.2
}

pydicom_main() {
    codes_dependencies common
    pydicom_python_versions=3
}

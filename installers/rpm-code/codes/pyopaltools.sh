#!/bin/bash

pyopaltools_main() {
    codes_dependencies common
    codes_download https://gitlab.psi.ch/OPAL/pyOPALTools/-/archive/pyOPALTools-0.0.1/pyOPALTools-pyOPALTools-0.0.1.tar.bz2
}

pyopaltools_python_install() {
    cd pyOPALTools*
#TODO(robnagler) there's no setup.py so install files
    codes_python_install
}

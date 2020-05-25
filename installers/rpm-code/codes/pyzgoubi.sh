#!/bin/bash

pyzgoubi_python_install() {
    pip install pyzgoubi==0.7.0b1
    perl -pi -e "s{(?<=^#\!).*}{$(pyenv which python)}" "$(pyenv which pyzgoubi)"
}

pyzgoubi_main() {
    codes_dependencies common
    pyzgoubi_python_version=2
}

#!/bin/bash

pyzgoubi_python_install() {
    cd pyzgoubi
    codes_python_install
}

pyzgoubi_main() {
    codes_dependencies common
    codes_download pyzgoubi py3
}

#!/bin/bash
bnlcrl_main() {
    codes_dependencies common
}

bnlcrl_python_install() {
    codes_download mrakitin/bnlcrl
    codes_python_install
}

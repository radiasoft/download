#!/bin/bash
bnlcrl_main() {
    codes_dependencies common
}

bnlcrl_python_install() {
    codes_download radiasoft/bnlcrl pyproject
    codes_python_install
}

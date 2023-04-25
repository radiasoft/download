#!/bin/bash

rshellweg_main() {
    codes_dependencies common boost
    codes_download radiasoft/rshellweg
}

rshellweg_python_install() {
    cd rshellweg
    CFLAGS=-I${codes_dir[include]} codes_python_install
}

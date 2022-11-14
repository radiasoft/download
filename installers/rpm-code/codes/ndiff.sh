#!/bin/bash

ndiff_main() {
    codes_dependencies common
    codes_download quinoacomputing/ndiff
    codes_cmake
    codes_make
    install -m 555 --strip maddiff "${codes_dir[bin]}"/ndiff
}
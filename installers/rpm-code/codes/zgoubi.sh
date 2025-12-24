#!/bin/bash

zgoubi_main() {
    codes_dependencies common pyzgoubi
    codes_download radiasoft/zgoubi
    set -x
    # Lots of warnings so disable
    # PUBLIC is on target fminigraf.c
    perl -pi -e 's{-Wall}{-w};s{(?<=PUBLIC)}{ -std=gnu11}' CMakeLists.txt
    perl -pi -e 'm{^#include..string.h} && ($_ .= qq{#include <time.h>\n})' zpop/liblns/fminigraf.c
    codes_cmake2
    codes_cmake_build install
}

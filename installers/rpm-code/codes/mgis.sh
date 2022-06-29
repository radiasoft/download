#!/bin/bash

mgis_main() {
    codes_dependencies common boost fenics
    codes_download thelfer/MFrontGenericInterfaceSupport
    local f
    for f in $(find . -name 'CMakeLists.txt'); do
        sed -i '1s/^/set(CMAKE_CXX_STANDARD 17)\nset(CXX_STANDARD_REQUIRED ON)\n/' "$f"
    done
    codes_cmake \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -DPYTHON_INCLUDE_DIR="$(codes_python_include_dir)"\
        -DPYTHON_LIBRARY="$(codes_python_lib_dir)" \
        -Denable-fenics-bindings=ON \
        -Denable-python-bindings=ON
    codes_make
    codes_make_install
    local d="${codes_dir[lib]}"/python3.7/site-packages/mgis
    mv "$d" "$(codes_python_lib_dir)"
    rmdir --ignore-fail-on-non-empty --parents "$(dirname "$d")"
}

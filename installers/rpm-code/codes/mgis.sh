#!/bin/bash

mgis_main() {
    codes_dependencies common boost fenics
    mgis_mgis
    mgis_mfront
}

mgis_mfront() {
    codes_download thelfer/tfel TFEL-4.0.0
    # TODO(e-carlin):  should probably add -Denable-python-bindings
    # TODO(e-carlin):  try remove python_iclude_dir and python_library and instead use Python_ADDITIONAL_VERSIONS
    codes_cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -DPYTHON_INCLUDE_DIR="$(codes_python_include_dir)"\
        -DPYTHON_LIBRARY="$(codes_python_lib_dir)" \
        -Denable-python=ON \
        -Denable-reference-doc=OFF \
        -Denable-website=OFF
    codes_make
    codes_make_install
}

mgis_mgis() {
    declare p="$PWD"
    # POSIT: Using TFEL-4.0.0 which is the version supported by MFrontGenericInterfaceSupport-2.0
    codes_download thelfer/MFrontGenericInterfaceSupport MFrontGenericInterfaceSupport-2.0
    declare f
    for f in $(find . -name 'CMakeLists.txt'); do
        sed -i '1s/^/set(CMAKE_CXX_STANDARD 17)\nset(CXX_STANDARD_REQUIRED ON)\n/' "$f"
    done
    codes_cmake \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -DPYTHON_INCLUDE_DIR="$(codes_python_include_dir)"\
        -DPYTHON_LIBRARY="$(codes_python_lib_dir)" \
        -Denable-fenics-bindings=ON \
        -Denable-python-bindings=ON
    # python should be installed in pyenv_prefix not prefix
    for f in $(find bindings/python -name 'cmake_install.cmake'); do
        # TODO(e-carlin):  codes_python_lib_dir is unquoted. discuss with rjn how to fix
        sed -i "1iset(CMAKE_INSTALL_PREFIX ${codes_dir[pyenv_prefix]})" "$f"
    done
    codes_make
    codes_make_install
    cd "$p"
}

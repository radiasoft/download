#!/bin/bash

ml_main() {
    codes_yum_dependencies graphviz
    codes_dependencies common pydot
}

ml_python_install() {
    install_pip_install h5ImageGenerator \
        scikit-learn sympy \
        tensorflow~=2.15.0
}

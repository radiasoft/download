#!/bin/bash

ml_for_py3_main() {
    codes_yum_dependencies graphviz
    codes_dependencies common pydot
    ml_for_py3_python_versions=3
}

ml_for_py3_python_install() {
    # sympy is needed for webcon
    pip install keras \
        scikit-learn \
        sympy \
        tensorflow
}

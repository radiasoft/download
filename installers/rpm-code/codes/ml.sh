#!/bin/bash

ml_main() {
    codes_yum_dependencies graphviz
    codes_dependencies common pydot
}

ml_python_install() {
    # sympy is needed for webcon and rsbeams
    # scikit-image is need for srw
    pip install keras \
        scikit-image \
        scikit-learn \
        tensorflow
}

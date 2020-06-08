#!/bin/bash

ml_main() {
    codes_yum_dependencies graphviz
    codes_dependencies common pydot
}

ml_python_install() {
    # sympy is needed for webcon
    # scikit-image is need for srw
    # installs "PIL", needed by srw and scikit-image so explicit here
    pip install keras \
        Pillow \
        scikit-image \
        scikit-learn \
        sympy \
        tensorflow
}

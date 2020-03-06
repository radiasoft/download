#!/bin/bash
ml_for_py3_main() {
    codes_dependencies common
    codes_yum_dependencies graphviz
    ml_for_py3_python_versions=3
}

ml_for_py3_python_install() {
    # pydot is needed for keras to access graphviz
    pip install pydot keras scikit-learn tensorflow
}

#!/bin/bash
pydot_python_install() {
    pip install pydot
}

pydot_main() {
    codes_dependencies common
    pydot_python_versions=3
}

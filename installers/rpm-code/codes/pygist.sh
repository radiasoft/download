#!/bin/bash
codes_dependencies common
pygist_python_versions=2

pygist_python_install() {
    codes_download https://bitbucket.org/dpgrote/pygist.git
    python setup.py config
    codes_python_install
}

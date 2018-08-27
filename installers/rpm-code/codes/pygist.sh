#!/bin/bash
codes_dependencies common
codes_download https://bitbucket.org/dpgrote/pygist.git
python setup.py config
codes_python_install

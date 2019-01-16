#!/bin/bash
codes_dependencies common
codes_download radiasoft/zgoubi
codes_cmake -DCMAKE_INSTALL_PREFIX:PATH="$(pyenv prefix)"
codes_make_install
pip install pyzgoubi

#!/bin/bash
codes_dependencies xraylib
pip install srxraylib
# fix https://github.com/radiasoft/download/issues/54
# codes_download oasys-kit/shadow3
codes_download PaNOSC-ViNYL/shadow3 gfortran8-fixes
codes_python_install
# line 639 of ShadowLibExtensions.py has a non-breaking utf8 character
# https://www.python.org/dev/peps/pep-0263/ says must define coding
for f in "$(codes_python_lib_dir)"/Shadow/*.py; do
    perl -pi -e 'print("# -*- coding: utf-8 -*-\n") if $. == 1' "$f"
done

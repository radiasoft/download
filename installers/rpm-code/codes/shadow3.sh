#!/bin/bash
codes_dependencies xraylib
codes_download srio/shadow3
codes_python_install
# line 639 of ShadowLibExtensions.py has a non-breaking utf8 character
# https://www.python.org/dev/peps/pep-0263/ says must define coding
for f in "$(codes_pylib_dir)"/Shadow/*.py; do
    perl -pi -e 'print("# -*- coding: utf-8 -*-\n") if $. == 1' "$f"
done

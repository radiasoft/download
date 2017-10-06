#!/bin/bash
codes_download pykern
# https://github.com/pytest-dev/pytest/issues/935
pip uninstall -y pykern >& /dev/null || true
for f in pytest-xdist pytest-forked pykern; do
    pip uninstall -y "$f" >& /dev/null || true
done
pip install -r requirements.txt
python setup.py install
pyenv rehash
hash pykern

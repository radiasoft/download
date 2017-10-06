#!/bin/bash
codes_download pykern
pip install -r requirements.txt
python setup.py install
pyenv rehash
hash pykern
# https://github.com/pytest-dev/pytest/issues/935
# This forces an order to plugins of a sort
codes_msg 'installing pytest plugins to force import order'
for f in pytest-xdist pytest-forked; do
    pip uninstall -y "$f" >& /dev/null || true
    pip install -y "$f"
done

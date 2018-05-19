#!/bin/bash
codes_download pykern
pip uninstall -y pykern >& /dev/null || true
python setup.py install
pyenv rehash
hash pykern

#!/bin/bash
codes_download pykern
pip uninstall -y pykern >& /dev/null || true
pip install -r requirements.txt
python setup.py install
pyenv rehash
hash pykern

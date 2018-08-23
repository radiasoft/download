#!/bin/bash
codes_dependencies opal
# https://gitlab.psi.ch/OPAL/pyOPALTools 500MB with data set
codes_download_foss pyOPALTools-20180207.120530.tar.gz
python setup.py install

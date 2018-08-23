#!/bin/bash
codes_dependencies common
codes_download mrakitin/bnlcrl
codes_patch_requirements_txt
python setup.py install

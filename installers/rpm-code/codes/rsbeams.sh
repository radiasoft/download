#!/bin/bash
codes_dependencies common
rsbeams_pwd=$PWD
for r in rsbeams rssynergia rsoopic rswarp; do
    codes_download radiasoft/"$r"
    codes_patch_requirements_txt
    python setup.py install
    cd "$rsbeams_pwd"
done

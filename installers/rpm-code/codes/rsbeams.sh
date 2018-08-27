#!/bin/bash
codes_dependencies common
rsbeams_pwd=$PWD
for r in rsbeams rssynergia rsoopic rswarp; do
    codes_download radiasoft/"$r"
    codes_patch_requirements_txt
    codes_python_install
    cd "$rsbeams_pwd"
done

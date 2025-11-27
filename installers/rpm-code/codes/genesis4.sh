#!/bin/bash
#
# Genesis Version4 was a re-write of Version3. Many things (ex input
# file format) changed in a backwards incompatible way. So, we are
# going to install Version3 (genesis.sh) and Version4 (gensis4.sh)
# side-by-side until the breakage is fixed.
#

genesis4_main() {
    codes_dependencies common impactt genesis
    codes_download https://github.com/svenreiche/Genesis-1.3-Version4.git
    codes_cmake
    codes_make all
    install -m 555 genesis4 "${codes_dir[bin]}"/genesis4
    # Fix the version
    codes_download https://github.com/slaclab/lume-genesis.git v1.3.6
    # hand edited list from environment.yml since not in pyproject.toml
    declare x=(
        eval-type-backport
        h5py
        jinja2
        lark
        lume-base
        matplotlib
        numpy
        'openpmd-beamphysics>=0.9.10'
        prettytable
        psutil
        pydantic-settings
        'pydantic>2'
        typing-extensions
    )
    install_pip_install "${x[@]}"
    codes_python_install
}

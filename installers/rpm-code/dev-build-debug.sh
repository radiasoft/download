#!/bin/bash
#
# Build without outside of a Docker container for debugging a code.
# Will not install the RPM, and will also muck up your VM by installing
# in ~/.local and ~/.pyenv
#
cd "$(dirname "$0")"
export install_tmp_dir=$PWD/tmp
rm -rf "$install_tmp_dir"
mkdir -p "$install_tmp_dir"
export install_debug=1
export rpm_code_debug=1
source dev-build.sh

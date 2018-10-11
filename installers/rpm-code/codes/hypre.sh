#!/bin/bash
codes_dependencies common
codes_download_foss hypre-2.11.2.tar.gz
cd src
./configure --prefix="$(pyenv prefix)"
codes_make_install

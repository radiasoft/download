#!/bin/bash
codes_dependencies common
codes_download_foss hypre-2.11.2.tar.gz
cd src
./configure --prefix="$(pyenv prefix)"
# hypre install does a chmod -R on install dirs, which
# makes a mess of things so install manually.
codes_make_install all
# src/hypre is where the build takes place
install -m 644 hypre/lib/* "$(pyenv prefix)"/lib
install -m 644 hypre/include/* "$(pyenv prefix)"/include

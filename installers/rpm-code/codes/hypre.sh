#!/bin/bash

hypre_main() {
    codes_dependencies common
    codes_download https://github.com/hypre-space/hypre/archive/v2.11.2.tar.gz
    cd src
    ./configure --prefix="${codes_dir[prefix]}"
    # hypre install does a chmod -R on install dirs, which
    # makes a mess of things so install manually.
    codes_make all
    # src/hypre is where the build takes place
    install -m 644 hypre/lib/* "${codes_dir[lib]}"
    install -m 644 hypre/include/* "${codes_dir[include]}"
}

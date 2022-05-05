#!/bin/bash

hypre_main() {
    codes_dependencies common
    codes_download https://github.com/hypre-space/hypre/archive/v2.24.0.tar.gz
    cd src
    local -a a=()
    if [[ ${1:-} == 'gpu-only' ]]; then
        #POSIT: container-jupyter-nvidia (cuda-11.2)
        # and running on Tesla V100 (arch 70)
        a=(
            --enable-unified-memory
            --with-cuda
            --with-cuda-home=/usr/local/cuda-11.2
            --with-gpu-arch=70
        )
    fi
    ./configure \
        --prefix="${codes_dir[prefix]}" \
        "${a[@]}"
    # hypre install does a chmod -R on install dirs, which
    # makes a mess of things so install manually.
    codes_make all
    # src/hypre is where the build takes place
    install -m 644 hypre/lib/* "${codes_dir[lib]}"
    install -m 644 hypre/include/* "${codes_dir[include]}"
}

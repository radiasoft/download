#!/bin/bash

libtorch_main() {
    codes_dependencies common
    # POSIT: Same version of torch as in ml-python
    # codes_download https://download.pytorch.org/libtorch/cu121/libtorch-cxx11-abi-shared-with-deps-2.1.0%2Bcu121.zip libtorch libtorch-gpu 2.1.0
    codes_download https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-2.1.0%2Bcpu.zip libtorch libtorch-cpu 2.1.0
    declare f
    for f in include lib; do
        mv "$f"/* "${codes_dir[$f]}"
    done
    mv  share/cmake/* "${codes_dir[lib]}"/cmake
}

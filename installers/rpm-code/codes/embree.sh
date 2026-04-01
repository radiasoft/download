#!/bin/bash

embree_main() {
    codes_yum_dependencies tbb-devel
    codes_dependencies common
    codes_download https://github.com/RenderKit/embree/archive/refs/tags/v4.4.0.tar.gz embree-4.4.0 embree 4.4.0
    codes_cmake2 \
        -DEMBREE_COMPACT_POLYS=ON \
        -DEMBREE_IGNORE_CMAKE_CXX_FLAGS=OFF \
        -DEMBREE_ISA_AVX2=OFF \
        -DEMBREE_ISA_AVX512=OFF \
        -DEMBREE_ISA_AVX=ON \
        -DEMBREE_ISA_SSE2=ON \
        -DEMBREE_ISA_SSE4=ON \
        -DEMBREE_ISPC_SUPPORT=OFF \
        -DEMBREE_MAX_ISA=NONE \
        -DEMBREE_STATIC_LIB=OFF \
        -DEMBREE_TESTING=OFF \
        -DEMBREE_TUTORIALS=OFF
    codes_cmake_build install
}

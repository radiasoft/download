#!/bin/bash

madness_main() {
    # requested https://github.com/radiasoft/download/issues/609
    codes_yum_dependencies gperftools
    codes_dependencies common
    # TODO(robnagler) This commit was around the time of the last build 2/19/2024, but still fails
    codes_download m-a-d-n-e-s-s/madness df98068830cf126c70bac6468668f244b8ec28eb
    # Tried this, but it didn't help
    # -D BUILD_TESTING=OFF
    # -D CMAKE_CXX_STANDARD=17 \
    codes_cmake2 \
        -D ENABLE_GPERFTOOLS=ON
    codes_cmake_build install
}

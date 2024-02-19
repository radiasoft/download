#!/bin/bash

madness_main() {
    # TODO(e-carlin): enable tbb: "-D MADNESS_TASK_BACKEND=TBB"
    # tbb from fedora repos is too old. Need to have at least 4.3.5.
    # https://github.com/oneapi-src/oneTBB
    # TODO(e-carlin):  enable mkl: "-D ENABLE_MKL=ON"
    # It is an intel lib and not available in fedora repos. Need to add intel repos.
    # Add repo: https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-download.html?operatingsystem=linux&distributions=dnf
    # dnf install -y intel-mkl
    # https://www.r-bloggers.com/2020/10/installing-and-switching-to-mkl-on-fedora/
    codes_yum_dependencies gperftools
    codes_dependencies common
    codes_download https://github.com/m-a-d-n-e-s-s/madness.git
    codes_cmake_fix_lib_dir
    codes_cmake \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D ENABLE_GPERFTOOLS=ON
    codes_make_install
}

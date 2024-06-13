#!/bin/bash

openpmdapi_main() {
    codes_dependencies common
    # POSIT: Version that impactx and waprx want
    # https://github.com/ECP-WarpX/impactx/blob/24.05/cmake/dependencies/ABLASTR.cmake#L197
    # https://github.com/ECP-WarpX/WarpX/blob/24.05/cmake/dependencies/openPMD.cmake#L95
    codes_download https://github.com/openPMD/openPMD-api/archive/refs/tags/0.15.2.tar.gz openPMD-api-0.15.2 openpmdapi 0.15.2
    codes_cmake_fix_lib_dir
    codes_cmake2  \
      -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"  \
      -DopenPMD_INSTALL_PYTHONDIR="$(codes_python_lib_dir)" \
      -DopenPMD_USE_MPI=ON \
      -DopenPMD_USE_PYTHON=ON
    codes_cmake_build install
}

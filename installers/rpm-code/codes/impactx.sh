#!/bin/bash

impactx_main() {
    # use warpx provides ablastr so a good dependency
    codes_dependencies warpx
    # POSIT: Same version as amrex and pyamrex
    codes_download https://github.com/ECP-WarpX/impactx/archive/25.11.tar.gz  impactx-25.11 impactx 25.11
    # Impactx defaults to appending all options to the binary filename.
    # So, create a symlink from that name to impactx.
    # This is already done for lib files.
    # Ex impactx.MPI.OMP -> impactx
    # https://github.com/ECP-WarpX/impactx/blob/2370b2696b32453c28a0a0f3e7ed6241e7f537d9/cmake/ImpactXFunctions.cmake#L248
    # https://github.com/ECP-WarpX/impactx/blob/2370b2696b32453c28a0a0f3e7ed6241e7f537d9/CMakeLists.txt#L347
    patch CMakeLists.txt <<'EOF'
@@ -349,6 +349,11 @@
     \"${ABS_INSTALL_LIB_DIR}/libimpactx$<TARGET_FILE_SUFFIX:lib>\"
     COPY_ON_ERROR SYMBOLIC)")

+install(CODE "file(CREATE_LINK
+    $<TARGET_FILE_NAME:app>
+    \"${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/impactx$<TARGET_FILE_SUFFIX:app>\"
+    COPY_ON_ERROR SYMBOLIC)")
+
 # CMake package file for find_package(ImpactX::ImpactX) in depending projects
 #install(EXPORT ImpactXTargets
 #    FILE ImpactXTargets.cmake
EOF
    CXXFLAGS=-Wno-template-body \
        codes_cmake2  \
        -DAMReX_OMP=ON \
        -DImpactX_PYTHON=ON \
        -DImpactX_amrex_internal=OFF \
        -DImpactX_openpmd_internal=OFF \
        -DImpactX_pyamrex_internal=OFF
    codes_cmake_build install
    codes_cmake_build pip_install
    # so does not conflict with warp's ablastr
    rm -f "${codes_dir[pyenv_prefix]}"/lib/libablstr.a
}

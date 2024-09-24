#!/bin/bash

impactx_main() {
    codes_dependencies common amrex openpmdapi pyamrex
    # POSIT: Same version as amrex and pyamrex
    codes_download https://github.com/ECP-WarpX/impactx/archive/24.09.tar.gz  impactx-24.09 impactx 24.09
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
    codes_cmake_fix_lib_dir
    codes_cmake2  \
      -DAMReX_OMP=ON \
      -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"  \
      -DImpactX_PYTHON=ON \
      -DImpactX_amrex_internal=OFF \
      -DImpactX_openpmd_internal=OFF \
      -DImpactX_pyamrex_internal=OFF
    # TODO(e-carlin): When
    # https://github.com/ECP-WarpX/impactx/issues/634 is fixed we can
    # remove this and instead create rscode-ablastr and depend on it.
    # rscode-warpx also installs ablastr so this would conflict with
    # it.
    echo '' > build/_deps/fetchedablastr-build/cmake_install.cmake
    codes_cmake_build install
    codes_cmake_build pip_install
}

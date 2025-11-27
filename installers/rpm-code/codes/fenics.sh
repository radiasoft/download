#!/bin/bash

fenics_python_install() {
    export BOOST_DIR=${codes_dir[prefix]} PETSC_DIR=${codes_dir[prefix]} SLEPC_DIR=${codes_dir[prefix]}
    codes_download https://github.com/FEniCS/dolfinx.git v0.10.0 dolfinx 0.10.0
    codes_cmake2 -DCMAKE_INSTALL_PREFIX="${codes_dir[pyenv_prefix]}" -DPYBIND11_TEST=False
    codes_make install
    cd ../..
    install_pip_install 'fenics>=2019.1.0,<2019.2.0'
    codes_download https://bitbucket.org/fenics-project/dolfin.git 2019.1.0.post0
    fenics_patch_dolfin
    # Error is "Could not find DOLFIN pkg-config file"
    codes_cmake_fix_lib_dir
    codes_cmake -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make install
    cd ../python
    codes_python_install
    cd ../..
    codes_download https://bitbucket.org/fenics-project/mshr.git 2019.1.0
    codes_cmake -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make install
    cd ../python
    codes_python_install
    cd ../..
    unset BOOST_DIR PETSC_DIR SLEPC_DIR
}

fenics_main() {
    codes_yum_dependencies mpfr-devel gmp-devel
    codes_dependencies petsc slepc
}

fenics_patch_dolfin() {
    git apply <<EOF
diff --git a/dolfin/geometry/IntersectionConstruction.cpp b/dolfin/geometry/IntersectionConstruction.cpp
index 765dbb6..7ba99a8 100644
--- a/dolfin/geometry/IntersectionConstruction.cpp
+++ b/dolfin/geometry/IntersectionConstruction.cpp
@@ -18,6 +18,7 @@
 // First added:  2014-02-03
 // Last changed: 2017-12-12

+#include <algorithm>
 #include <iomanip>
 #include <dolfin/mesh/MeshEntity.h>
 #include "predicates.h"
diff --git a/dolfin/io/HDF5Interface.cpp b/dolfin/io/HDF5Interface.cpp
index 02bfd58..7bcf113 100644
--- a/dolfin/io/HDF5Interface.cpp
+++ b/dolfin/io/HDF5Interface.cpp
@@ -281,8 +281,8 @@ bool HDF5Interface::has_group(const hid_t hdf5_file_handle,
     return false;
   }

-  H5O_info_t object_info;
-  H5Oget_info_by_name(hdf5_file_handle, group_name.c_str(), &object_info,
+  H5O_info1_t object_info;
+  H5Oget_info_by_name1(hdf5_file_handle, group_name.c_str(), &object_info,
                       lapl_id);

   // Close link access properties
diff --git a/dolfin/io/VTKFile.cpp b/dolfin/io/VTKFile.cpp
index 2fee53b..85c4ebc 100644
--- a/dolfin/io/VTKFile.cpp
+++ b/dolfin/io/VTKFile.cpp
@@ -20,7 +20,7 @@
 #include <vector>
 #include <iomanip>
 #include <boost/cstdint.hpp>
-#include <boost/detail/endian.hpp>
+#include <boost/predef/other/endian.h>

 #include "pugixml.hpp"

@@ -614,9 +614,9 @@ void VTKFile::vtk_header_open(std::size_t num_vertices, std::size_t num_cells,
   std::string endianness = "";
   if (encode_string == "binary")
   {
-    #if defined BOOST_LITTLE_ENDIAN
+    #if defined BOOST_ENDIAN_LITTLE_BYTE
     endianness = "byte_order=\"LittleEndian\"";
-    #elif defined BOOST_BIG_ENDIAN
+    #elif defined BOOST_ENDIAN_BIG_BYTE
     endianness = "byte_order=\"BigEndian\"";;
     #else
     dolfin_error("VTKFile.cpp",
diff --git a/dolfin/io/VTKWriter.cpp b/dolfin/io/VTKWriter.cpp
index eff6934..b57a665 100644
--- a/dolfin/io/VTKWriter.cpp
+++ b/dolfin/io/VTKWriter.cpp
@@ -24,7 +24,6 @@
 #include <sstream>
 #include <vector>
 #include <iomanip>
-#include <boost/detail/endian.hpp>

 #include <dolfin/fem/GenericDofMap.h>
 #include <dolfin/fem/FiniteElement.h>
diff --git a/dolfin/la/PETScKrylovSolver.cpp b/dolfin/la/PETScKrylovSolver.cpp
index e729093..8ad33a2 100644
--- a/dolfin/la/PETScKrylovSolver.cpp
+++ b/dolfin/la/PETScKrylovSolver.cpp
@@ -497,7 +497,7 @@ void PETScKrylovSolver::monitor(bool monitor_convergence)
     PetscViewerAndFormat *vf;
     PetscViewerAndFormatCreate(viewer,format,&vf);
     ierr = KSPMonitorSet(_ksp,
-                         (PetscErrorCode (*)(KSP,PetscInt,PetscReal,void*)) KSPMonitorTrueResidualNorm,
+                         (PetscErrorCode (*)(KSP,PetscInt,PetscReal,void*)) KSPMonitorTrueResidual,
                          vf,
                          (PetscErrorCode (*)(void**))PetscViewerAndFormatDestroy);
     if (ierr != 0) petsc_error(ierr, __FILE__, "KSPMonitorSet");
diff --git a/dolfin/mesh/MeshFunction.h b/dolfin/mesh/MeshFunction.h
index 08cbc82..4e68324 100644
--- a/dolfin/mesh/MeshFunction.h
+++ b/dolfin/mesh/MeshFunction.h
@@ -27,6 +27,7 @@
 #include <map>
 #include <vector>

+#include <algorithm>
 #include <memory>
 #include <unordered_set>
 #include <dolfin/common/Hierarchical.h>
diff --git a/dolfin/nls/PETScSNESSolver.cpp b/dolfin/nls/PETScSNESSolver.cpp
index 71bca08..0153ae2 100644
--- a/dolfin/nls/PETScSNESSolver.cpp
+++ b/dolfin/nls/PETScSNESSolver.cpp
@@ -517,7 +517,7 @@ void PETScSNESSolver::set_linear_solver_parameters()
       ierr = PetscViewerAndFormatCreate(viewer,format,&vf);
       if (ierr != 0) petsc_error(ierr, __FILE__, "PetscViewerAndFormatCreate");
       ierr = KSPMonitorSet(ksp,
-                           (PetscErrorCode (*)(KSP,PetscInt,PetscReal,void*)) KSPMonitorTrueResidualNorm,
+                           (PetscErrorCode (*)(KSP,PetscInt,PetscReal,void*)) KSPMonitorTrueResidual,
                            vf,
                            (PetscErrorCode (*)(void**))PetscViewerAndFormatDestroy);
       if (ierr != 0) petsc_error(ierr, __FILE__, "KSPMonitorSet");
diff --git a/dolfin/nls/PETScTAOSolver.cpp b/dolfin/nls/PETScTAOSolver.cpp
index cebb0de..035f49a 100644
--- a/dolfin/nls/PETScTAOSolver.cpp
+++ b/dolfin/nls/PETScTAOSolver.cpp
@@ -577,7 +577,7 @@ void PETScTAOSolver::set_ksp_options()
         PetscViewerAndFormat *vf;
         ierr = PetscViewerAndFormatCreate(viewer,format,&vf);
         ierr = KSPMonitorSet(ksp,
-                         (PetscErrorCode (*)(KSP,PetscInt,PetscReal,void*)) KSPMonitorTrueResidualNorm,
+                         (PetscErrorCode (*)(KSP,PetscInt,PetscReal,void*)) KSPMonitorTrueResidual,
                          vf,
                          (PetscErrorCode (*)(void**))PetscViewerAndFormatDestroy);
         if (ierr != 0) petsc_error(ierr, __FILE__, "KSPMonitorSet");
diff --git a/dolfin/nls/TAOLinearBoundSolver.cpp b/dolfin/nls/TAOLinearBoundSolver.cpp
index 0ca775c..9e12fb3 100644
--- a/dolfin/nls/TAOLinearBoundSolver.cpp
+++ b/dolfin/nls/TAOLinearBoundSolver.cpp
@@ -413,7 +413,7 @@ void TAOLinearBoundSolver::set_ksp_options()
         PetscViewerFormat format = PETSC_VIEWER_DEFAULT;
         PetscViewerAndFormat *vf;
         ierr = PetscViewerAndFormatCreate(viewer,format,&vf);
-        ierr = KSPMonitorSet(ksp, (PetscErrorCode (*)(KSP,PetscInt,PetscReal,void*)) KSPMonitorTrueResidualNorm,
+        ierr = KSPMonitorSet(ksp, (PetscErrorCode (*)(KSP,PetscInt,PetscReal,void*)) KSPMonitorTrueResidual,
                              vf,(PetscErrorCode (*)(void**))PetscViewerAndFormatDestroy);
         if (ierr != 0) petsc_error(ierr, __FILE__, "KSPMonitorSet");
       }
EOF
}

#!/bin/bash

fnal_chef_main() {
    codes_yum_dependencies eigen3-devel gsl-devel
    codes_dependencies common boost pydot
    codes_download https://bitbucket.org/fnalacceleratormodeling/chef.git mac-native
}

fnal_chef_python_install() {
    cd chef
patch CMakeLists.txt <<'EOF'
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 574164a9..be4f99e9 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -58,86 +58,14 @@ endif()
 # Find necessary packages
 ##

-# python
-if (USE_PYTHON_3)
-  message(STATUS "Trying to find python 3")
-  message(STATUS "A failure here is not fatal... we'll try differently later")
-  set(Python_ADDITIONAL_VERSIONS "3")
-  find_package(Python3 COMPONENTS Interpreter Development)
-  if (Python3_FOUND)
-    message(STATUS "We found Python 3")
-    message(STATUS "Python3_LIBRARIES: ${Python3_LIBRARIES}")
-    set(MY_PYTHON_LIBRARY ${Python3_LIBRARIES})
-    set(MY_PYTHON_EXECUTABLE ${Python3_EXECUTABLE})
-    set(MY_PYTHON_INCLUDE_DIRECTORY ${Python3_INCLUDE_DIRS})
-    set(MY_PYTHON_VERSION_MAJOR ${Python3_VERSION_MAJOR})
-    set(MY_PYTHON_VERSION_MINOR ${Python3_VERSION_MINOR})
-  endif()
-else()
-  message(STATUS "Trying to find python 2")
-  message(STATUS "A failure here is not fatal... we'll try differently later")
-  set(Python_ADDTIONAL_VERSIONS "2")
-  find_package(Python2 COMPONENTS Interpreter Development)
-  if (Python2_FOUND)
-    set(MY_PYTHON_LIBRARY ${Python2_LIBRARIES})
-    set(MY_PYTHON_EXECUTABLE ${Python2_EXECUTABLE})
-    set(MY_PYTHON_INCLUDE_DIRECTORY ${Python2_INCLUDE_DIRS})
-    set(MY_PYTHON_VERSION_MAJOR ${Python2_VERSION_MAJOR})
-    set(MY_PYTHON_VERSION_MINOR ${Python2_VERSION_MINOR})
-  endif()
-endif()
-
-# If we could use cmake v3.12 or newer, this would not be needed.
-if (NOT MY_PYTHON_LIBRARY)
-  message(STATUS "First attempt to find Python failed; trying fallback technique...")
-  message(STATUS "Python_ADDITIONAL_VERSIONS is: ${Python_ADDITIONAL_VERSIONS}")
-  find_package(PythonInterp REQUIRED)
-  find_package(PythonLibs REQUIRED)
-  set(MY_PYTHON_LIBRARY ${PYTHON_LIBRARIES})
-  set(MY_PYTHON_EXECUTABLE ${PYTHON_EXECUTABLE})
-  set(MY_PYTHON_INCLUDE_DIRECTORY ${PYTHON_INCLUDE_DIRS})
-  set(MY_PYTHON_VERSION_MAJOR ${PYTHON_VERSION_MAJOR})
-  set(MY_PYTHON_VERSION_MINOR ${PYTHON_VERSION_MINOR})
-endif()
 include_directories(${MY_PYTHON_INCLUDE_DIR})

-message(STATUS "Done looking for Python")
-message(STATUS "MY_PYTHON_VERSION_MAJOR is: ${MY_PYTHON_VERSION_MAJOR}")
-message(STATUS "MY_PYTHON_VERSION_MINOR is: ${MY_PYTHON_VERSION_MINOR}")
-
 include(${CHEF_SOURCE_DIR}/CMake/AddPythonExtension.cmake)

 # boost
 set(Boost_NO_BOOST_CMAKE ON) # Do *not* use CMake support from Boost.
 set(Boost_USE_STATIC_LIBS OFF)
 set(Boost_USE_MULTITHREAD ON)
-find_package(Boost
-             REQUIRED
-             COMPONENTS regex unit_test_framework serialization system)
-set(first_boost_libraries ${Boost_LIBRARIES})
-set(first_boost_library_dirs ${Boost_LIBRARY_DIRS})
-
-if (USE_PYTHON_3)
-    set(pstem python3 python35 python36 python37 python38)
-else()
-    set(pstem python python27)
-endif()
-
-# Go through all relevant possible choices of boost library name, stopping
-# when we find one that works.
-message(STATUS "Looking for best choice of boost.python library")
-foreach (plib ${pstem})
-    message(STATUS "trying component name ${plib}")
-    find_package(Boost QUIET COMPONENTS ${plib})
-    if (Boost_LIBRARIES)
-      string(TOUPPER "${plib}" MY_PYLIB)
-      set(MY_BOOST_PYTHON_LIBRARY "${Boost_${MY_PYLIB}_LIBRARY}")
-      message(STATUS "success for name ${plib}")
-      break()
-    endif()
-endforeach()
-set(Boost_LIBRARIES ${first_boost_libraries} ${Boost_LIBRARIES})
-set(Boost_LIBRARY_DIRS ${first_boost_library_dirs} ${Boost_LIBRARY_DIRS})

 include_directories(${Boost_INCLUDE_DIRS})
 link_directories(${Boost_LIBRARY_DIRS})
@@ -170,12 +98,10 @@ endif()
 ### reasonable location.
 set(INCLUDE_INSTALL_DIR include/ CACHE PATH "include install directory")
 set(LIB_INSTALL_DIR lib/ CACHE PATH "library install directory")
-set(PYTHON_INSTALL_DIR "lib/python${MY_PYTHON_VERSION_MAJOR}.${MY_PYTHON_VERSION_MINOR}/site-packages"
+set(PYTHON_INSTALL_DIR ${MY_PYTHON_INSTALLDIR}
     CACHE PATH "python install directory")
 include_directories(BEFORE "${CHEF_BINARY_DIR}/${INCLUDE_INSTALL_DIR}")

-# numpy
-find_package(NUMPY REQUIRED)
 include_directories(${NUMPY_INCLUDE_DIR})

 ##
EOF
    $(python <<'EOF'
import numpy
import platform
import sys
import sysconfig
s = sysconfig.get_config_vars()
v = platform.python_version_tuple()
l = sysconfig.get_path("purelib")[len(s["base"])+1:]
print(f"""
local numpy_include="{numpy.get_include()}";
local py_code={v[0]}{v[1]};
local py_exe={sys.executable};
local py_include="{s["CONFINCLUDEPY"]}";
local py_ldlib="{s["LIBDIR"]}/{s["LDLIBRARY"]}";
local py_major={v[0]};
local py_minor={v[1]};
local py_install="{l}"
""")
EOF
)
    codes_cmake \
        -DBoost_INCLUDE_DIRS="${codes_dir[include]}" \
        -DBoost_LIBRARIES="${codes_dir[lib]}/libboost_regex.so;${codes_dir[lib]}/libboost_unit_test_framework.so;${codes_dir[lib]}/libboost_serialization.so;${codes_dir[lib]}/libboost_system.so" \
        -DBoost_LIBRARY_DIRS="${codes_dir[lib]}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DFFTW3_LIBRARY_DIRS=/usr/lib64/mpich/lib \
        -DMY_BOOST_PYTHON_LIBRARY="$(find ${codes_dir[lib]} -name libboost_python$py_code.so)"
        -DMY_PYTHON_EXECUTABLE="$py_exe" \
        -DMY_PYTHON_INCLUDE_DIRECTORY="$py_include" \
        -DMY_PYTHON_LIBRARY="$py_ldlib" \
        -DMY_PYTHON_VERSION_MAJOR="$py_major" \
        -DMY_PYTHON_VERSION_MINOR="$py_minor" \
        -DNUMPY_INCLUDE_DIR="$numpy_include" \
        -DMY_PYTHON_INSTALL_DIR="$py_install" \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[pyenv_prefix]}" ..
    codes_make_install
}

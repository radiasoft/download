#!/bin/bash

synergia_python_install() {
    cd synergia2
    patch CMakeLists.txt <<'EOF'
diff --git a/CMakeLists.txt b/CMakeLists.txt
index c060f1e7..5ee0e465 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -55,85 +55,14 @@ endif()
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
-    # If we could use cmake v3.12 or newer, this is simple:
-    #find_package(Python3 COMPONENTS Interpreter Development)
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
-    # If we could use cmake v3.12 or newer, this is simple:
-    #find_package(Python3 COMPONENTS Interpreter Development)
-  endif()
-endif()
-
-# If we could use cmake v3.12 or newer, this would not be needed.
-if (NOT MY_PYTHON_LIBRARY)
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
 include(${SYNERGIA2_SOURCE_DIR}/CMake/AddPythonExtension.cmake)

 # boost
 set(Boost_NO_BOOST_CMAKE ON) # Do *not* use CMake support from Boost.
 set(Boost_USE_STATIC_LIBS OFF)
 set(Boost_USE_MULTITHREAD ON)
-find_package(Boost
-             REQUIRED
-             COMPONENTS regex unit_test_framework serialization system filesystem)
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
-foreach (plib ${pstem})
-    find_package(Boost QUIET COMPONENTS ${plib})
-    if (Boost_LIBRARIES)
-      string(TOUPPER "${plib}" MY_PYLIB)
-      set(MY_BOOST_PYTHON_LIBRARY "${Boost_${MY_PYLIB}_LIBRARY}")
-      break()
-    endif()
-endforeach()
-set(Boost_LIBRARIES ${first_boost_libraries} ${Boost_LIBRARIES})
-set(Boost_LIBRARY_DIRS ${first_boost_library_dirs} ${Boost_LIBRARY_DIRS})

 include_directories(${Boost_INCLUDE_DIRS})
 link_directories(${Boost_LIBRARY_DIRS})
@@ -180,7 +109,6 @@ include_directories(${CHEF_INCLUDE_DIR})
 link_directories(${CHEF_LIB_DIR})

 # numpy
-find_package(NUMPY REQUIRED)
 include_directories(${NUMPY_INCLUDE_DIR})

 # mpi4py
EOF
    $(python <<'EOF'
import numpy
import mpi4py
import platform
import sysconfig
s = sysconfig.get_config_vars()
v = platform.python_version_tuple()
print(f"""
local numpy_include={numpy.get_include()}
local mpi4py_include={mpi4py.get_include()}
local py_code={v[0]}{v[1]}
local py_include={s["CONFINCLUDEPY"]}
local py_ldlib={s["LIBDIR"]}/{s["LDLIBRARY"]}
""")
EOF
)
    # EXTRA_CXX_FLAGS, because synergia won't compile without them
    CHEF_INSTALL_DIR="${codes_dir[pyenv_prefix]}" \
        codes_cmake \
        -DBoost_FILESYSTEM_LIBRARY="${codes_dir[lib]}/libboost_filesystem.so" \
        -DBoost_INCLUDE_DIRS="${codes_dir[include]}" \
        -DBoost_LIBRARIES="${codes_dir[lib]}/libboost_regex.so;${codes_dir[lib]}/libboost_unit_test_framework.so;${codes_dir[lib]}/libboost_serialization.so;${codes_dir[lib]}/libboost_system.so;${codes_dir[lib]}/libboost_filesystem.so" \
        -DBoost_LIBRARY_DIRS="${codes_dir[lib]}" \
        -DBoost_REGEX_LIBRARY="${codes_dir[lib]}/libboost_regex.so" \
        -DBoost_SERIALIZATION_LIBRARY="${codes_dir[lib]}/libboost_serialization.so" \
        -DBoost_SYSTEM_LIBRARY="${codes_dir[lib]}/libboost_system.so" \
        -DBoost_UNIT_TEST_FRAMEWORK_LIBRARY="${codes_dir[lib]}/libboost_unit_test_framework.so" \
        -DCMAKE_BUILD_TYPE=Release \
        -DEXTRA_CXX_FLAGS='-Wno-deprecated-declarations -Wno-sign-compare -Wno-maybe-uninitialized' \
        -DFFTW3_LIBRARY_DIRS=/usr/lib64/mpich/lib \
        -DMY_BOOST_PYTHON_LIBRARY="$(find ${codes_dir[lib]} -name libboost_python$py_code.so)" \
        -DMY_PYTHON_INCLUDE_DIR="$py_include" \
        -DMY_PYTHON_LIBRARY="$py_ldlib" \
        -DNUMPY_INCLUDE_DIR="$numpy_include" \
        -DMPI4PY_INCLUDE_DIR="$mpi4py_include" \
        -DUSE_SIMPLE_TIMER=0 \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[pyenv_prefix]}"
    codes_make_install
    local l="$(codes_python_lib_dir)"
    mv "${codes_dir[pyenv_prefix]}"/lib/{synergia,synergia_tools,synergia_workflow} "$l"
    echo '#' > "$l"/synergia_tools/__init__.py
}

synergia_main() {
    codes_dependencies fnal_chef
    codes_download https://bitbucket.org/fnalacceleratormodeling/synergia2.git mac-native
}

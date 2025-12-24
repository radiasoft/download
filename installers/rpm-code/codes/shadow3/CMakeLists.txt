cmake_minimum_required(VERSION 3.18)
project(shadow3 LANGUAGES C Fortran)

# scikit-build-core expects this
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# -std=gnu11
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)

# Python dev (for the ShadowLib binding)
find_package(Python REQUIRED COMPONENTS Interpreter Development.Module NumPy)


# Fortran + C sources for the core shadow3c library
file(GLOB_RECURSE SHADOW3_FORTRAN
     "${CMAKE_CURRENT_SOURCE_DIR}/src/*.f"
     "${CMAKE_CURRENT_SOURCE_DIR}/src/*.f90"
)
file(GLOB SHADOW3_C
     "${CMAKE_CURRENT_SOURCE_DIR}/src/c/*.c"
)

add_definitions( -D_COMPILE4NIX=1 )
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-incompatible-pointer-types")
# -g -O0
# set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
# Don’t strip on install
# set(CMAKE_INSTALL_DO_STRIP OFF CACHE BOOL "" FORCE)
# Effectively disable strip tool
# set(CMAKE_STRIP "" CACHE FILEPATH "" FORCE)

add_compile_options(
    $<$<COMPILE_LANGUAGE:Fortran>:-cpp>
    $<$<COMPILE_LANGUAGE:Fortran>:-ffree-line-length-none>
    $<$<COMPILE_LANGUAGE:Fortran>:-fomit-frame-pointer>
    $<$<COMPILE_LANGUAGE:Fortran>:-I${CMAKE_BINARY_DIR}/path/to/clib>
#    $<$<COMPILE_LANGUAGE:Fortran>:-g>
#    $<$<COMPILE_LANGUAGE:Fortran>:-O0>
)


add_library(shadow3c STATIC
    "src/c/shadow_bind_c.c"
    # The order of these files matters, because fortran
    # compilers need the "*.mod" files for "use" statements
    # "fortran/shadow_version.f90",
    "src/fortran/shadow_globaldefinitions.f90"
    "src/fortran/stringio.f90"
    "src/fortran/gfile.f90"
    "src/fortran/shadow_beamio.f90"
    "src/fortran/shadow_math.f90"
    "src/fortran/shadow_variables.f90"
    "src/fortran/shadow_roughness.f90"
    "src/fortran/shadow_kernel.f90"
    "src/fortran/shadow_synchrotron.f90"
    "src/fortran/shadow_pre_sync.f90"
    "src/fortran/shadow_pre_sync_urgent.f90"
    "src/fortran/shadow_preprocessors.f90"
    "src/fortran/shadow_postprocessors.f90"
    "src/fortran/shadow_bind_f.f90"
    "src/fortran/shadow_crl.f90"
)

# Python wrapper (was setuptools.Extension(name='Shadow.ShadowLib', ...))
add_library(ShadowLib MODULE
    src/c/shadow_bind_python.c
)

target_include_directories(ShadowLib
    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/src/c"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/def"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/fortran"
        ${Python_NumPy_INCLUDE_DIRS}
        ${Python_INCLUDE_DIRS}
)

target_include_directories(shadow3c
    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/src/c"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/fortran"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/def"
        ${Python_NumPy_INCLUDE_DIRS}
        ${Python_INCLUDE_DIRS}
)

target_link_libraries(ShadowLib
    PRIVATE
        shadow3c
        Python::Module
)

# Match the old extension name: Shadow.ShadowLib
set_target_properties(ShadowLib PROPERTIES
    OUTPUT_NAME "ShadowLib"
    PREFIX ""                # no 'lib' prefix on POSIX
)

# Install the extension into the Shadow package
install(TARGETS ShadowLib
        LIBRARY DESTINATION Shadow
)

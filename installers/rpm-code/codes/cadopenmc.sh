#!/bin/bash
_cadopenmc_gmsh_py_d=gmsh-py

_cadopenmc_gmsh_version=4.11.1

cadopenmc_gmsh() {
    codes_download https://gmsh.info/src/gmsh-"$_cadopenmc_gmsh_version"-source.tgz
    # Even though not installing, we need CMAKE_INSTALL_PREFIX to allow gmsh to find
    # opencascade.
    codes_cmake2 \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D ENABLE_BUILD_SHARED=ON \
        -D ENABLE_CAIRO=OFF \
        -D ENABLE_FLTK=OFF \
        -D ENABLE_RPATH=OFF \
        -D ENABLE_TESTS=OFF \
        -D ENABLE_TOUCHBAR=OFF
    codes_cmake_build
    # See cadopenmc_py
    declare d=../$_cadopenmc_gmsh_py_d/gmsh
    mkdir -p "$d"
    cp -a api/gmsh.py "$d"/__init__.py
    # This copies all symlinks. gmsh.py hardwires the major.minor version so
    # really need all three. pip will create "-<version>" files which is a pain, but
    # not much to do about it.
    cp -a build/libgmsh.so.* "$d"
}

cadopenmc_main() {
    codes_yum_dependencies libglvnd-devel
    codes_dependencies common
    cadopenmc_opencascade
    cadopenmc_gmsh
}

cadopenmc_opencascade() {
    codes_download_foss opencascade-7.7.0.tar.gz
    codes_cmake2 \
        -D BUILD_CPP_STANDARD=C++11 \
        -D BUILD_Inspector=OFF \
        -D BUILD_LIBRARY_TYPE=Shared \
        -D BUILD_MODULE_ApplicationFramework=OFF \
        -D BUILD_MODULE_DataExchange=ON \
        -D BUILD_MODULE_Draw=OFF \
        -D BUILD_MODULE_ModelingAlgorithms=ON \
        -D BUILD_MODULE_ModelingData=ON \
        -D BUILD_MODULE_Visualization=OFF \
        -D BUILD_SAMPLES_QT=OFF \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -D INSTALL_SAMPLES=OFF \
        -D INSTALL_TEST_CASES=OFF \
        -D USE_DRACO=OFF \
        -D USE_FREEIMAGE=OFF \
        -D USE_FREETYPE=OFF \
        -D USE_GLES2=OFF \
        -D USE_OPENGL=OFF \
        -D USE_OPENVR=OFF \
        -D USE_RAPIDJSON=OFF \
        -D USE_TBB=OFF \
        -D USE_TK=OFF \
        -D USE_VTK=OFF
    codes_cmake_build install
    cd ..
}

cadopenmc_python_install() {
    cadopenmc_python_install_gmsh
    pip install CAD_to_OpenMC
}

cadopenmc_python_install_gmsh() {
    cd "$_cadopenmc_gmsh_py_d"
    cat > pyproject.toml <<'EOF'
[build-system]
requires = ["setuptools"]
build-backend = "setuptools.build_meta"
EOF
    cat > setup.cfg <<EOF
[metadata]
name = gmsh
version = $_cadopenmc_gmsh_version

[options]
packages = find:
include_package_data = True
EOF
    cat > MANIFEST.in <<'EOF'
include gmsh/*
EOF
    pip install .
}

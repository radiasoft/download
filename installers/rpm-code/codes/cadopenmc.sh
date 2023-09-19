#!/bin/bash
_cadopenmc_gmsh_py_d=gmsh-py

_cadopenmc_gmsh_version=4.11.1

cadopenmc_gmsh() {
    codes_download https://gmsh.info/src/gmsh-"$_cadopenmc_gmsh_version"-source.tgz
    codes_cmake2 \
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

cadopenmc_gmsh_py() {
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

cadopenmc_main() {
    codes_dependencies common
    cadopenmc_gmsh
}

cadopenmc_python_install() {
    cadopenmc_gmsh_py
    pip install CAD_to_OpenMC
}

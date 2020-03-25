#!/bin/bash

fnal_chef_python_install() {
    mkdir chef/build
    cd chef/build
    cmake \
        -DBOOST_ROOT="${codes_dir[prefix]}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DFFTW3_LIBRARY_DIRS=/usr/lib64/mpich/lib \
        -DUSE_PYTHON_3=1 \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[pyenv_prefix]}" ..
    codes_make_install
}


fnal_chef_main() {
    # pyparsing is required by matplotlib
    codes_dependencies common boost
    codes_yum_dependencies eigen3-devel gsl-devel
    codes_download https://bitbucket.org/fnalacceleratormodeling/chef.git mac-native
    fnal_chef_python_versions=3
}

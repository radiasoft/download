#!/bin/bash

fnal_chef_main() {
    codes_yum_dependencies eigen3-devel gsl-devel
    codes_dependencies common boost pydot
    codes_download https://bitbucket.org/fnalacceleratormodeling/chef.git mac-native
}

fnal_chef_python_install() {
    cd chef
    perl -pi -e 's{(?<=find_package.Python3)}{ 3.7.2 EXACT REQUIRED}' CMakeLists.txt
    codes_cmake \
        -D BOOST_ROOT=$HOME/.local \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[pyenv_prefix]}" \
        -D FFTW3_LIBRARY_DIRS=/usr/lib64/mpich/lib \
        -D USE_PYTHON_3=1
    codes_make_install
}

#!/bin/bash

fnal_chef_main() {
    codes_yum_dependencies eigen3-devel gsl-devel
    codes_dependencies common boost pydot
    codes_download https://bitbucket.org/fnalacceleratormodeling/chef.git mac-native
}

fnal_chef_python_install() {
    cd chef
-Wno-error=deprecated-declarations

/home/vagrant/src/radiasoft/codes/fnal_chef-20220614.144145/chef/build/include/basic_toolkit/TVector.h:203:30: error: ‘template<class _Arg1, class _Arg2, class _Result> struct std::binary_function’ is deprecated [-Werror=deprecated-declarations]
  203 |   class op_mult: public std::binary_function<std::complex<double>&, std::complex<double>&, std::complex<double> > {
      |                              ^~~~~~~~~~~~~~~
-Werror=deprecated-declarations

    perl -pi -e "s{(?<=find_package.Python3)}{ $RADIA_RUN_VERSION_PYTHON EXACT REQUIRED}" CMakeLists.txt
    codes_cmake \
        -D BOOST_ROOT="${codes_dir[prefix]}" \
        -D CMAKE_INSTALL_PREFIX="${codes_dir[pyenv_prefix]}" \
        -D FFTW3_LIBRARY_DIRS=/usr/lib64/mpich/lib \
        -D USE_PYTHON_3=1
    codes_make_install
}

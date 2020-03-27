#!/bin/bash

xraylib_main() {
    codes_yum_dependencies swig
    codes_dependencies common
}

xraylib_python_install() {
    codes_download http://lvserver.ugent.be/xraylib/xraylib-3.2.0.tar.gz
    # can't use codes_dir[prefix], because it installs ~/.local/lib/python3.7
    # instead of asking python where to install.
    ./configure --prefix="${codes_dir[pyenv_prefix]}" \
        --enable-python --disable-perl \
        --disable-ruby \
        --disable-python-numpy \
        --disable-fortran2003
    codes_make
    codes_make_install
}

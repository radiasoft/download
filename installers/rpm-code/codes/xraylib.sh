#!/bin/bash
codes_yum_dependencies swig
codes_dependencies common
codes_download http://lvserver.ugent.be/xraylib/xraylib-3.2.0.tar.gz
./configure --prefix="$(pyenv prefix)" \
    --enable-python --disable-perl \
    --disable-ruby \
    --disable-python-numpy \
    --disable-fortran2003
make
codes_make_install
ls ~/.pyenv/versions/py2/lib
~/.pyenv/versions/py2/share

#!/bin/bash

pyopaltools_main() {
    codes_dependencies common
    # https://gitlab.psi.ch/OPAL/pyOPALTools 500MB with data set
    codes_download_foss pyOPALTools-20180207.120530.tar.gz
    # pyOPALTools directory causes an error in fpm:
    # dr-xr-x--- 8 vagrant vagrant  242 Feb  7  2018 pyOPALTools
    # `link': Permission denied @ rb_file_s_link
    chmod -R u+w .
    pyopaltools_python_version=2
}

pyopaltools_python_install() {
    codes_python_install
}

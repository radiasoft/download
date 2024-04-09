#!/bin/bash

epics_pvxs_main() {
    codes_yum_dependencies libevent-devel
    codes_dependencies epics
    codes_download_nonrecursive=1 codes_download https://github.com/mdavidsaver/pvxs.git
    # unnecessary and take a long time
    perl -pi -e '/test|example/ && s{^}{#}' Makefile
    codes_epics_include_dir=pvxs codes_epics_make_install
}

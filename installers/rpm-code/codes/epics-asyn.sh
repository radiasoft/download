#!/bin/bash

epics_asyn_main() {
    codes_yum_dependencies libtirpc-devel rpcgen
    codes_dependencies epics
    codes_download https://github.com/epics-modules/asyn/archive/R4-43.tar.gz asyn-R4-43 asyn R4-43
    codes_epics_release_local=$'TIRPC=YES\nEPICS_LIBCOM_ONLY=YES' codes_epics_make_install
}

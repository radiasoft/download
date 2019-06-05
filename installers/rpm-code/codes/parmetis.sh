#!/bin/bash
codes_dependencies common
#http://glaros.dtc.umn.edu/gkhome/metis/parmetis/download
codes_download_foss parmetis-4.0.3.tar.gz
make config prefix="${codes_dir[prefix]}"
codes_make_install

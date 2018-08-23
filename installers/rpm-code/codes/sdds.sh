#!/bin/bash
codes_dependencies common
sdds_pwd=$PWD
codes_download_foss SDDSToolKit-3.5.1-1.fedora.27.x86_64.rpm
rpm_code_build_install_files+=( $(rpm -ql SDDSToolKit) )
cd "$sdds_pwd"
codes_download_foss SDDSPython-3.2-1.fedora.27.x86_64.rpm
install -m 0644 $(rpm -ql SDDSPython | grep ^/usr/lib/python2.7/site-packages) "$codes_lib_dir"

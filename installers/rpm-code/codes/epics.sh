#!/bin/bash
codes_dependencies common
codes_download https://epics.anl.gov/download/base/base-7.0.2.tar.gz
d=$HOME/epics
cat > configure/CONFIG_SITE.local <<EOF
INSTALL_LOCATION = $d
EPICS_HOST_ARCH = linux-x86_64
EOF
make -j"$(codes_num_cores)"
rpm_code_build_include_add "$d"

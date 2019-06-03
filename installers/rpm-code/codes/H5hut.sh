#!/bin/bash
codes_dependencies common
# original source has bad ssl cert:
# http://amas.web.psi.ch/Downloads/H5hut/H5hut-2.0.0rc3.tar.gz
# Doc: https://gitlab.psi.ch/H5hut/src/wikis/home
codes_download_foss H5hut-2.0.0rc3.tar.gz
perl -pi -e 's{\`which}{\`type -p}' autogen.sh
./autogen.sh
perl -pi -e 's{\`which}{\`type -p}' configure
CC=mpicc CXX=mpicxx ./configure \
  --enable-parallel \
  --prefix="$(codes_dir)" \
  --with-pic
codes_make_install

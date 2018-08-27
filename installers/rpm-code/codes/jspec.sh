#!/bin/bash
codes_dependencies common
codes_yum_dependencies muParser-devel
codes_download zhanghe9704/electroncooling master
mkdir build
cd build
cmake ..
codes_make_install all
install -m 755 jspec "$(pyenv prefix)"/bin/jspec
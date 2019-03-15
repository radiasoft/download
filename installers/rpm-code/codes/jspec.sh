#!/bin/bash
codes_dependencies common
codes_yum_dependencies muParser-devel
codes_download zhanghe9704/electroncooling 176878a40750872802a3ae7aa26c928f199a3d1c
codes_cmake
codes_make_install all
install -m 755 jspec "$(pyenv prefix)"/bin/jspec

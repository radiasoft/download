#!/bin/bash
codes_dependencies common
codes_yum_dependencies muParser-devel
codes_download zhanghe9704/electroncooling 73c67070e74ee802cbed2eea720fa023a695163f
codes_cmake
codes_make_install all
install -m 755 jspec "$(pyenv prefix)"/bin/jspec

#!/bin/bash
codes_dependencies common
codes_yum_dependencies muParser-devel
codes_download zhanghe9704/electroncooling 25230771a3cc01cb5d354015bfedb28d6bd178be
codes_cmake
codes_make_install all
install -m 755 jspec "$(pyenv prefix)"/bin/jspec

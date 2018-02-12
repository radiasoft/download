#!/bin/bash
codes_yum install muParser
codes_download zhanghe9704/electroncooling master
mkdir build
cd build
CMAKE_PREFIX_PATH="$(pyenv prefix)" cmake ..
codes_make_install

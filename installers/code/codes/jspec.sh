#!/bin/bash
codes_download zhanghe9704/electroncooling master
mkdir build
CMAKE_PREFIX_PATH="$(pyenv prefix)" cmake ..
codes_make_install

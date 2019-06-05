#!/bin/bash
codes_dependencies common
codes_yum_dependencies muParser-devel
codes_download radiasoft/electroncooling
codes_cmake
codes_make_install all
install -m 755 jspec "${codes_dir[bin]}"/jspec

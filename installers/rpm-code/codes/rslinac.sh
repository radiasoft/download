#!/bin/bash
codes_yum_dependencies boost-devel
codes_download radiasoft/rslinac beamsim_build
python setup.py install

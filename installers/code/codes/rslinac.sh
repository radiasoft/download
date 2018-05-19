#!/bin/bash
codes_yum install boost-devel
codes_download radiasoft/rslinac beamsim_build
python setup.py install

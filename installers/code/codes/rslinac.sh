#!/bin/bash
codes_yum install boost-devel
# Working commit on integration branch
codes_download radiasoft/rslinac b0c58164f8405a976a06a5f89e27808abc474307
python setup.py install

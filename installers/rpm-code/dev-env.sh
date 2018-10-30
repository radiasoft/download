#!/bin/bash
# intended to be sourced
export dev_port=1313
export install_server=http://$(hostname -f):$dev_port
export rpm_code_yum_dir=$HOME/src/yum/fedora/27/x86_64/dev

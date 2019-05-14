#!/bin/bash
# intended to be sourced
export dev_port=2916
export install_server=http://$(hostname -f):$dev_port
export rpm_code_yum_dir=$HOME/src/yum/fedora/29/x86_64/dev

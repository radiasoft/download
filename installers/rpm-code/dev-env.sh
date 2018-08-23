#!/bin/bash
# intended to be sourced
export dev_port=1313
export install_server=http://$(hostname -f):$dev_port
export GNUPGHOME=$(cd $(dirname $0); pwd)/gnupg.d

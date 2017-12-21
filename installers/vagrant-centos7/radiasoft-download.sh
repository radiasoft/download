#!/bin/bash
#
# Create a Centos 7 VirtualBox
#
# Usage: curl radia.run | bash -s vagrant-centos7 [guest-name:v.radia.run [guest-ip:10.10.10.10]]
#
install_repo_eval vagrant-dev centos/7 "${install_extra_args[@]}"

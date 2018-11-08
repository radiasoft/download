#!/bin/bash
codes_dependencies common
bnlcrl_python_versions='2 3'

bnlcrl_python_install() {
    codes_download mrakitin/bnlcrl
    codes_python_install
}

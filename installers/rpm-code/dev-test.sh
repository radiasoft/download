#!/bin/bash
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh
x=$(bash dev-build.sh test)
re='RPM_CODE_TEST_VERSION=([0-9]+\.[0-9]+)'
if [[ ! $x =~ $re ]]; then
    echo "FAIL: did not find RPM_CODE_TEST_VERSION in: $x" 1>&2
    exit 1
fi
x=$rpm_code_install_dir/rscode-test-${BASH_REMATCH[1]}-1.x86_64.rpm
actual="$(rpm -qlp "$x" | sort)"
expect="/home/vagrant/.local/bin/rscode-test
/home/vagrant/.local/etc/bashrc.d/my.sh
/home/vagrant/.pyenv/versions/3.9.15/envs/py3/lib/python3.9/site-packages/my.py
/home/vagrant/.pyenv/versions/3.9.15/envs/py3/xyz
/home/vagrant/.pyenv/versions/3.9.15/envs/py3/xyz/PASS"
if [[ $expect != $actual ]]; then
    echo "FAIL: unexpected output from:
rpm -qlp $x

!$actual!" 1>&2
    exit 1
fi
echo PASSED

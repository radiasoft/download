#!/bin/bash
set +euo pipefail
source ~/.bashrc
set -euo pipefail
source ./dev-env.sh
x=$(bash dev-build.sh test)
re='RPM_CODE_TEST_VERSION=([0-9]+\.[0-9]+)'
if [[ ! $x =~ $re ]]; then
    echo "FAIL: did not find RPM_CODE_TEST_VERSION in: $x" 1>&2
    exit 1
fi
x=$rpm_code_yum_dir/rscode-test-${BASH_REMATCH[1]}-1.x86_64.rpm
actual="$(rpm -qlp "$x" | sort)"
expect='/home/vagrant/.pyenv/versions/py2/bin/rscode-test
/home/vagrant/.pyenv/versions/py2/xyz
/home/vagrant/.pyenv/versions/py2/xyz/PASS'
if [[ $expect != $actual ]]; then
    echo "FAIL: unexpected output of:
rpm -qlp $x
$actual" 1>&2
    exit 1
fi
echo PASSED
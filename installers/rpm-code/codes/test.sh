#!/bin/bash
install -m 555 /dev/stdin "$codes_bin_dir/rscode-test" <<EOF
#!/bin/bash
set -x
echo 'PASSED. Also must pass:
rpm -ql rscode-test-$version*rpm | grep FAIL'
EOF
codes_yum_dependencies rootfiles
pyenv rehash
_share=$(pyenv prefix)/share
mkdir -p "$_share"
# otherwise directories are owned by root
echo PASS > "$_share/PASS"
_fail="$(pyenv prefix)/FAIL"
mkdir -p "$_fail"
rpm_code_build_include_add "$_share"
rscode-test

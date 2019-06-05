#!/bin/bash
codes_dependencies common
install -m 555 /dev/stdin "${codes_dir[bin]}"/rscode-test <<EOF
#!/bin/bash
# POSIT: codes.sh sets locally-scoped version var
echo "RPM_CODE_TEST_VERSION=$version"
EOF
pyenv rehash
_xyz=$(pyenv prefix)/xyz
mkdir -p "$_xyz"
my_sh=${codes_dir[bashrc_d]}/my.sh
echo echo PASS > "$my_sh"
# otherwise directories are owned by root
echo PASS > "$_xyz/PASS"
_fail="$(pyenv prefix)/FAIL"
mkdir -p "$_fail"
rpm_code_build_include_add "$_xyz"
rpm_code_build_include_add "$my_sh"
rscode-test

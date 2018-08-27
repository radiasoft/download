#!/bin/bash
install -m 555 /dev/stdin "$codes_bin_dir/rscode-test" <<EOF
#!/bin/bash
echo 'Run this:

rpm -ql ~/src/yum/fedora/*/x86_64/dev/rscode-test-$version*rpm

which should produce:

/home/vagrant/.pyenv/versions/py2/bin/rscode-test
/home/vagrant/.pyenv/versions/py2/share
/home/vagrant/.pyenv/versions/py2/share/doc
/home/vagrant/.pyenv/versions/py2/share/doc/PASS
'
EOF
codes_yum_dependencies rootfiles
pyenv rehash
_share=$(pyenv prefix)/share
mkdir -p "$_share/doc"
# otherwise directories are owned by root
echo PASS > "$_share/doc/PASS"
_fail="$(pyenv prefix)/FAIL"
mkdir -p "$_fail"
rpm_code_build_include_add "$_share"
rscode-test

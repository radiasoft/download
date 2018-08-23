#!/bin/bash
install -m 555 /dev/stdin "$codes_bin_dir/rscode-test" <<EOF
#!/bin/bash
echo PASSED
EOF
codes_yum_dependencies rootfiles
pyenv rehash
rscode-test

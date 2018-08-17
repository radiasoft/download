#!/bin/bash
install -m 555 /dev/stdin "$codes_bin_dir/rscode-test" <<EOF
#!/bin/bash
echo PASSED
EOF
pyenv rehash
rscode-test

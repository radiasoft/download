#!/bin/bash

test_main() {
    install_msg "num_cores=$(codes_num_cores)"
    codes_dependencies common
    install -m 555 /dev/stdin "${codes_dir[bin]}"/rscode-test <<EOF
#!/bin/bash
echo "RPM_CODE_TEST_VERSION=$rpm_build_version"
EOF
    local my_sh=${codes_dir[bashrc_d]}/my.sh
    echo echo PASS > "$my_sh"
}

test_python_install() {
    local _xyz="${codes_dir[pyenv_prefix]}"/xyz
    mkdir -p "$_xyz"
    echo pass > my.py
    codes_python_lib_copy my.py
    # otherwise directories are owned by root
    echo PASS > "$_xyz/PASS"
    rscode-test
}

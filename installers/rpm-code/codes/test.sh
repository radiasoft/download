#!/bin/bash
cat >> ~/.post_bivio_bashrc <<'EOF'
pyenv() {
    case $1 in
        prefix)
            echo /home/vagrant/.pyenv/versions/2.7.16/envs/py2
            ;;
        activate|rehash)
            ;;
        *)
            echo "unknown pyenv mock command=$1" 1>&2
            exit 1
            ;;
    esac
}
EOF

# mock
codes_python_lib_dir() {
    echo /home/vagrant/.pyenv/versions/py2/lib/python2.7/site-packages
}


test_main() {
    codes_dependencies common-test
    install -m 555 /dev/stdin "${codes_dir[bin]}"/rscode-test <<EOF
#!/bin/bash
# POSIT: codes.sh sets locally-scoped version var
echo "RPM_CODE_TEST_VERSION=$version"
EOF
    install_source_bashrc
    local my_sh=${codes_dir[bashrc_d]}/my.sh
    echo echo PASS > "$my_sh"
    rpm_code_build_include_add "$my_sh"
    test_python_versions=2
}

test_python_install() {
    local _xyz="${codes_dir[pyenv_prefix]}"/xyz
    mkdir -p "$_xyz"
    echo pass > my.py
    codes_python_lib_copy my.py
    # otherwise directories are owned by root
    echo PASS > "$_xyz/PASS"
    local _fail="${codes_dir[pyenv_prefix]}/FAIL"
    mkdir -p "$_fail"
    rpm_code_build_include_add "$_xyz"
    rscode-test
}

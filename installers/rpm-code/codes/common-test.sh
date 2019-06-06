#!/bin/bash
cat >> ~/.post_bivio_bashrc <<'EOF'
pyenv() {
    case $1 in
        prefix)
            echo /home/vagrant/.pyenv/versions/py2
            ;;
        *)
            echo "unknown pyenv mock command=$1" 1>&2
            exit 1
            ;;
    esac
}
EOF
rpm_code_build_include_add ~/.post_bivio_bashrc
install_source_bashrc
codes_download_module_file pyenv.txz
(cd && tar xJpf -) < pyenv.txz
rpm_code_build_include_add ~/.pyenv
rpm_code_build_exclude_add "$HOME"/bin

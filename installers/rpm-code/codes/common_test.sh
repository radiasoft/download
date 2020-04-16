#!/bin/bash

common_test_main() {
    cat >> ~/.post_bivio_bashrc <<'EOF'
    pyenv() {
        case $1 in
            prefix)
                echo /home/vagrant/.pyenv/versions/2.7.16/envs/py2
                ;;
            rehash)
                ;;
            *)
                echo "unknown pyenv mock command=$1" 1>&2
                exit 1
                ;;
        esac
    }
EOF
    install_source_bashrc
    codes_download_module_file pyenv.txz
    (cd && tar xJpf -) < pyenv.txz
}

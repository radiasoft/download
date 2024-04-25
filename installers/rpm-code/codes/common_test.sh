#!/bin/bash

cat >> ~/.pre_bivio_bashrc <<'EOF'
pyenv() {
    case $1 in
        prefix)
            echo /home/vagrant/.pyenv/versions/2.7.16/envs/py2
            ;;
        activate|rehash|virtualenv-init|init)
            ;;
        *)
            echo "unknown pyenv mock command=$1" 1>&2
            exit 1
            ;;
    esac
}
EOF

common_test_main() {
    codes_download_module_file pyenv.txz
    (cd && tar xJpf -) < pyenv.txz
}

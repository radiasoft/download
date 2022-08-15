#!/bin/bash
#
# Create a rsconf dev box
#
set -euo pipefail

vagrant_rsconf_dev_main() {
    case $(basename "$PWD") in
        v3)
            vagrant_rsconf_dev_master
            ;;
        v2|v4|v5)
            vagrant_dev_no_docker_disk= vagrant_dev_barebones=1 \
                install_server=http://v3.radia.run:2916 \
                vagrant_rsconf_dev_worker
            ;;
        *)
            install_err 'Must be run from v2, v3, v4, or v5 dirs'
            ;;
   esac
}

vagrant_rsconf_dev_master() {
    install_repo_eval vagrant-dev centos
    vagrant ssh <<'EOF'
        bivio_pyenv_3
        set -euo pipefail
        mkdir -p ~/src/radiasoft
        cd ~/src/radiasoft
        gcl download
        gcl containers
        gcl pykern
        cd pykern
        pip install -e . | cat
        cd ..
        gcl rsconf
        cd rsconf
        pip install -e . | cat
        rsconf build
EOF
    local s=file:///home/vagrant/src/radiasoft/rsconf/run/srv
    install_server=$s vagrant_rsconf_dev_run || true
    vagrant reload
    install_server=$s vagrant_rsconf_dev_run
    # For building perl rpms (see build-perl-rpm.sh)
}

vagrant_rsconf_dev_run() {
    install_server=$install_server vagrant ssh -c 'sudo su -' <<EOF
        set -euo pipefail
        export install_channel=dev install_server=$install_server
        curl "$install_server/index.html" | bash -s rsconf.sh "\$(hostname -f)" setup_dev
EOF
}

vagrant_rsconf_dev_worker() {
    install_repo_eval vagrant-dev centos
    vagrant_rsconf_dev_run || true
    vagrant reload
    vagrant_rsconf_dev_run
}

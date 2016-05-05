#!/bin/bash
#
# To run: curl radia.run | sudo bash -s salt
#
set -e

salt_alarm() {
    local timeout=$1
    local rc=0 sleep_pid op_pid
    timeout=$1
    shift
    bash -c "$@" &
    op_pid=$!
    {
        sleep "$timeout"
        kill -9 "$op_pid" >& /dev/null || true
    } &
    sleep_pid=$!
    wait "$op_pid" >& /dev/null
    rc=$?
    kill "$sleep_pid" >& /dev/null || true
    return $rc
}

salt_assert() {
    if (( $UID != 0 )); then
        install_err 'Must run as root'
    fi
    if [[ ! -r /etc/fedora-release ]]; then
        install_err 'Only runs on Fedora'
    fi
    if ! grep -s -q ' 23 ' /etc/fedora-release; then
        install_err 'Only runs on Fedora 23'
    fi
}

salt_bootstrap() {
    install_download https://bootstrap.saltstack.com \
        | bash ${install_debug+-x} -s -- \
        -P -X -n ${install_debug+-D} -A $salt_master git develop
    if [[ ! -f /etc/salt/minion ]]; then
        install_err 'bootstrap.saltstrack.com failed'
    fi
    local res
    if ! res=$(systemctl status salt-minion 2>&1); then
        install_err '${res}salt-minion failed to start'
    fi
}

salt_conf() {
    local d=/etc/salt/minion.d
    mkdir -p "$d"
    install_url biviosoftware/salt-conf srv/salt/minion
    install_download bivio.conf no_shebang_check > "$d/bivio.conf"
}

salt_main() {
    salt_assert
    salt_master
    umask 022
    salt_pykern
    salt_conf
    salt_bootstrap
    chmod -R go-rwx /etc/salt /var/log/salt /var/cache/salt /var/run/salt
}

salt_master() {
    local res
    salt_master=${install_extra_args[0]}
    if [[ -z $salt_master ]]; then
        install_err 'Must supply salt master as extra argument'
    fi
    if ! res=$(salt_alarm 3 ": < '/dev/tcp/$salt_master/4505'"); then
        install_err "$res$salt_master: is invalid or inaccessible"
    fi
}

salt_pykern() {
    local pip=pip
    if [[ -z $(type -p pip) ]]; then
        pip=pip3
    fi
    # Packages needed by pykern, which is needed by our custom states/modules
    "$pip" install -U pip setuptools pytz docker-py
}

salt_main

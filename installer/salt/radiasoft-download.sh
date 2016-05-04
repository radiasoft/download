#!/bin/bash
#
# To run: curl radia.run | sudo bash -s salt
#
set -e

salt_alarm() {
    local timeout=$1
    timeout=$1
    shift
    bash -c "$@" &
    local op_pid=$!
    {
        sleep "$timeout"
        kill -9 "$op_pid" >& /dev/null
    } &
    local sleep_pid=$!
    wait "$op_pid" >& /dev/null
    local rc=$?
    kill "$sleep_pid" >& /dev/null
    return $rc
}

salt_assert() {
    if (( $UID != 0 )); then
        install_err 'Must run as root'
    fi
    if ! grep -s -q '\b23\b' /etc/fedora-release; then
        install_err 'Incorrect Fedora version (not 23.x) or not Fedora'
    fi
}

salt_bootstrap() {
    install_download http://salt.run \
        | bash -s -- -P -X -N -n ${install_verbose+-D} git develop
}

salt_conf() {
    local d=/etc/salt/minion.d
    mkdir -p "$d"
    install_url biviosoftware/salt-conf srv/salt/minion
    echo "master: $salt_master" > "$d/master.conf"
    install_download bivio.conf > "$d/bivio.conf"
    chmod -R go-rwx /etc/salt
}

salt_main() {
    salt_assert
    salt_master
    umask 022
    salt_conf
    salt_bootstrap
    salt_pykern
}

salt_master() {
    if [[ !$install_extra_args ]]; then
        install_err 'Must supply salt master as extra argument'
    fi
    salt_master=${install_extra_args[0]}
    local res=$(salt_alarm 3 ": < '/dev/tcp/$salt_master/4505'")
    if (( $? != 0 )); then
        install_err "$res$salt_master: is invalid or inaccessible"
    fi
}

salt_pykern() {
    # Needed packages to update
    pip update -U pip setuptools pytz
    pip install pykern
}

salt_main

#!/bin/bash
#
# To run: curl radia.run | sudo bash -s fedora-post <hostname> <salt-master>
#
fedora_post_host() {
    local host=$1
    if ! getent ahosts "$host" >& /dev/null; then
        install_err "$host: no such host"
    fi
    echo "$host" > /etc/hostname
    hostname "$host"
}

fedora_post_lvremove_home() {
    if grep -s -q ' /home ' /proc/mounts; then
        umount /home
    fi
    sed -e '/ \/home /d' < /etc/fstab > /etc/fstab.tmp
    cat /etc/fstab.tmp > /etc/fstab
    rm -f /etc/fstab.tmp
    if lvs fedora/home >& /dev/null; then
        lvremove -f /dev/mapper/fedora-home
    fi
}

fedora_post_main() {
    local host="${install_extra_args[0]}"
    local master="${install_extra_args[1]}"
    fedora_post_host "$host"
    fedora_post_lvremove_home
    fedora_post_salt "$master"
    install_msg "Finish on the salt master:
ssh $master
su -
service salt-master exec_bash
salt-key -y -a '$host'
cd /srv/pillar/minions
ln -s ../systems/TYPE.cfg MINION.bivio.biz
# Will 'fail'
salt state.apply
# second time required, because salt-minion restarts
salt state.apply
"
}

fedora_post_salt() {
    local master=$1
    if ! getent ahosts "$master" >& /dev/null; then
        install_err "$master: no such host"
    fi
    install_repo=salt
    install_extra_args=( $master )
    install_repo
}

fedora_post_main

#!/bin/bash
#
# Create a Centos or Fedora VirtualBox with guest additions
#
# Usage: curl radia.run | bash -s vagrant-up centos|fedora [guest-name:v.radia.run [guest-ip:10.10.10.10]]
#
set -euo pipefail

vagrant_dev_check() {
    local vdi=$1
    if [[ ! $(type -t vagrant) ]]; then
        install_err 'vagrant not installed. Please visit to install:

http://vagrantup.com'
    fi
    if [[ -d .vagrant ]]; then
        local s=$(vagrant status 2>&1)
        local re=' not created |machine is required to run'
        if [[ ! $s =~ $re ]]; then
            install_err 'vagrant machine exists. Please run: vagrant destroy -f'
        fi
    fi
    vagrant_dev_plugins
    vagrant_dev_vdi_delete "$vdi"
}

vagrant_dev_ip() {
    local host=$1
    local i=$(dig +short "$host" 2>/dev/null || true)
    if [[ $i ]]; then
        echo -n "$i"
        return
    fi
    case $host in
        v.radia.run)
            i=1
            ;;
        v[1-9].radia.run)
            i=${host:1:1}
            ;;
        *)
            install_err "$host: host not found and IP address not supplied"
            ;;
    esac
    echo -n 10.10.10.$(( 10 * $i ))
}

vagrant_dev_init_nfs() {
    if [[ ${vagrant_dev_no_mounts:+1} ]]; then
        return
    fi
    install_msg 'We need access to sudo on your Mac to mount NFS'
    if ! sudo true; then
        install_err 'must have access to sudo'
    fi
    if [[ ! -r /etc/exports ]]; then
        sudo touch /etc/exports
        # vagrant requires /etc/exports readable by an ordinary user
        sudo chmod 644 /etc/exports
    fi
}

vagrant_dev_main() {
    local os=${1:-} host=${2:-} ip=${3:-}
    if [[ ! $host ]]; then
        if [[ ! $PWD =~ /(v[2-9]?)$ ]]; then
            install_err 'either specify a host or run from directory named v, v2, v3, ..., v9'
        fi
        host=${BASH_REMATCH[1]}
    fi
    local base=${host%%.*}
    if [[ $base == $host ]]; then
        host=$host.radia.run
    fi
    if [[ ! $os =~ ^(fedora|centos) ]]; then
        install_err "$os: invalid OS: only fedora or centos are supported"
    fi
    if [[ ${vagrant_dev_barebones:+1} ]]; then
        # allow individual overrides
        vagrant_dev_no_dev_env=${vagrant_dev_no_dev_env-1}
        vagrant_dev_no_docker_disk=${vagrant_dev_no_docker_disk-1}
        vagrant_dev_no_mounts=${vagrant_dev_no_mounts-1}
        vagrant_dev_no_nfs_src=${vagrant_dev_no_nfs_src-1}
        vagrant_dev_no_vbguest=${vagrant_dev_no_vbguest-1}
    fi
    # Mounts only really work on Darwin for now
    if [[ ! ${vagrant_dev_no_mounts+1} && $(uname) != Darwin ]]; then
        vagrant_dev_no_mounts=1
        vagrant_dev_no_vbguest=${vagrant_dev_no_vbguest-1}
    fi
    if [[ ! ${vagrant_dev_no_nfs_src+1} && $os =~ centos ]]; then
        vagrant_dev_no_nfs_src=1
    fi
    if [[ ! $ip ]]; then
        ip=$(vagrant_dev_ip "$host")
    fi
    # Absolute path is necessary for comparison in vagrant_dev_delete_vdi
    vagrant_dev_init_nfs
    local vdi=$PWD/$base-docker.vdi
    vagrant_dev_check "$vdi"
    if [[ ! ${vagrant_dev_no_vbguest:+1} ]]; then
        vagrant_dev_vagrantfile "$os" "$host" "$ip" "$vdi" '1'
        vagrant up
        vagrant ssh <<'EOF'
sudo yum install -q -y kernel kernel-devel kernel-headers kernel-tools perl
EOF
        vagrant halt
    fi
    vagrant_dev_vagrantfile "$os" "$host" "$ip" "$vdi" ''
    vagrant up
    if [[ ${vagrant_dev_no_dev_env:+1} ]]; then
        return
    fi
    local f
    for f in ~/.gitconfig ~/.netrc; do
        if [[ -r $f ]]; then
            vagrant ssh -c "install -m 600 /dev/stdin $(basename $f)" < "$f" >& /dev/null
        fi
    done
    # file:// urls don't work inside the VM
    if [[ $install_server =~ ^file: ]]; then
        local install_server=
    fi
    vagrant ssh <<EOF
$(install_vars_export)
curl $(install_depot_server)/index.sh | bash -s redhat-dev
EOF
}

vagrant_dev_mounts() {
    if [[ ${vagrant_dev_no_mounts:+1} ]]; then
        echo 'config.vm.synced_folder ".", "/vagrant", disabled: true'
        return
    fi
    # Have to use vers=3 b/c vagrant will insert it (incorrectly) otherwise. Not sure why.
    local res=(
        'config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["rw", "vers=3", "tcp", "nolock", "fsc", "actimeo=2"]'
    )
    if [[ ! ${vagrant_dev_no_nfs_src:+1} ]]; then
        mkdir -p "$HOME/src"
        res+=( 'config.vm.synced_folder "'"$HOME/src"'", "/home/vagrant/src", type: "nfs", mount_options: ["rw", "vers=3", "tcp", "nolock", "fsc", "actimeo=2"]' )
    fi
    local IFS='
    '
    echo "${res[*]}"
}

vagrant_dev_plugins() {
    local x=()
    if [[ ! ${vagrant_dev_no_vbguest:+1} ]]; then
        x+=( vagrant-vbguest )
    fi
    if [[ ! ${vagrant_dev_no_docker_disk:+1} ]]; then
        x+=( vagrant-persistent-storage )
    fi
    if [[ ! ${x[@]+1} ]]; then
        return
    fi
    local plugins=$(vagrant plugin list)
    local p op
    for p in "${x[@]}"; do
        op=install
        if [[ $plugins =~ $p ]]; then
            op=update
        fi
        vagrant plugin "$op" "$p"
    done
}

vagrant_dev_vagrantfile() {
    local os=$1 host=$2 ip=$3 vdi=$4 first=$5
    local vbguest='' timesync=''
    if [[ ! ${vagrant_dev_no_vbguest:+1} ]]; then
        if [[ $first ]]; then
            vbguest='config.vbguest.auto_update = false'
        else
            # https://medium.com/carwow-product-engineering/time-sync-problems-with-vagrant-and-virtualbox-383ab77b6231
            timesync='v.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 5000]'
        fi
    fi
    local macos_fixes=
    if [[ $(uname) == Darwin ]]; then
        macos_fixes='v.customize [
            "modifyvm", :id,
                # Fix Mac thunderbolt issue
                "--audio", "none",
                # https://www.dbarj.com.br/en/2017/11/fixing-virtualbox-crashing-macos-on-high-load-kernel-panic/
                # https://stackoverflow.com/a/31425419
                "--paravirtprovider", "none",
        ]'
    fi
    local box=$os
    if [[ ${vagrant_dev_box:-} ]]; then
        box=$vagrant_dev_box
    elif [[ $os =~ fedora ]]; then
        if [[ $box == fedora ]]; then
            box=fedora/29-cloud-base
        fi
    elif [[ $box == centos ]]; then
        box=centos/7
    fi
    local mounts="$(vagrant_dev_mounts)"
    local persistent_storage=
    if [[ ! ${vagrant_dev_no_docker_disk:+1} ]]; then
        # read returns false
        IFS= read -r -d '' persistent_storage <<EOF || true
    # Create a disk for docker
    config.persistent_storage.enabled = true
    # so doesn't write signature
    config.persistent_storage.format = false
    # Clearer to add host name to file so that it can be distinguished
    # in VirtualBox Media Manager, which only shows file name, not full path.
    config.persistent_storage.location = "$vdi"
    # so doesn't modify /etc/fstab
    config.persistent_storage.mount = false
    # use whole disk
    config.persistent_storage.partition = false
    config.persistent_storage.size = 102400
    config.persistent_storage.use_lvm = true
    config.persistent_storage.volgroupname = "docker"
EOF
    fi
    cat > Vagrantfile <<EOF
# -*-ruby-*-
Vagrant.configure("2") do |config|
    config.vm.box = "$box"
    config.vm.hostname = "$host"
    config.vm.network "private_network", ip: "$ip"
    config.vm.provider "virtualbox" do |v|
        ${timesync}
        ${macos_fixes}
        # https://stackoverflow.com/a/36959857/3075806
        v.customize ["setextradata", :id, "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled", "0"]
        # If you see network restart or performance issues, try this:
        # https://github.com/mitchellh/vagrant/issues/8373
        # v.customize ["modifyvm", :id, "--nictype1", "virtio"]
        #
        # 8192 needed for compiling some the larger codes
        v.memory = ${vagrant_dev_memory:-8192}
        v.cpus = ${vagrant_dev_cpus:-4}
    end
${persistent_storage}
    config.ssh.forward_x11 = false
    ${vbguest}
    # https://stackoverflow.com/a/33137719/3075806
    # Undo mapping of hostname to 127.0.0.1
    config.vm.provision "shell",
        inline: "sed -i '/127.0.0.1.*$host/d' /etc/hosts"
    ${mounts}
end
EOF
}

vagrant_dev_vdi_delete() {
    # vdi might be leftover from previous vagrant up. VirtualBox doesn't
    # destroy automatically.
    local vdi=$1
    if [[ ! -e $vdi ]]; then
        return
    fi
    local uuid=$(vagrant_dev_vdi_find "$vdi")
    if [[ $uuid ]]; then
        install_info "Deleting HDD $vdi ($uuid)"
        VBoxManage closemedium disk "$uuid" --delete
    fi
}

vagrant_dev_vdi_find() {
    local vdi=$1
    VBoxManage list hdds | while read l; do
        if [[ ! $l =~ ^([^:]+):[[:space:]]*(.+) ]]; then
            continue
        fi
        case ${BASH_REMATCH[1]} in
            Location)
                if [[ $vdi == ${BASH_REMATCH[2]} ]]; then
                    echo "$u"
                    exit
                fi
                ;;
            UUID)
                u=${BASH_REMATCH[2]}
                ;;
        esac
    done
}

vagrant_dev_main ${install_extra_args[@]+"${install_extra_args[@]}"}

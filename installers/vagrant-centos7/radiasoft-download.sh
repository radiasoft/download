#!/bin/bash
#
# Create a Centos 7 VirtualBox
#
# Usage: curl radia.run | bash -s vagrant-up [guest-name:v.bivio.biz [guest-ip:10.10.10.10]]
#

# Delete the disk below. Not easy
# VBoxManage closemedium disk <uuid> --delete

# vbguest is useful for people not wanting to use nfs
# VBoxManage list hdds|tail
# vagrant plugin install vagrant-vbguest

vagrant_up_check() {
    local vdi=$1
    if [[ -z $(type -t vagrant) ]]; then
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
    if [[ -e $vdi ]]; then
        vagrant_up_delete_vdi "$vdi"
    else
        vagrant plugin install vagrant-persistent-storage
    fi
}

vagrant_up_delete_vdi() {
    # vdi might be leftover from previous vagrant up. VirtualBox doesn't
    # destroy automatically.
    local vdi=$1
    local l u uuid
    VBoxManage list hdds | while read l; do
        if [[ ! $l =~ ^[^:]+:[[:space:]]*(.+) ]]; then
            continue
        fi
        case $BASH_REMATCH[1] in
            Location)
                if [[ $vdi == $BASH_REMATCH[2] ]]; then
                    uuid=$u
                    break
                fi
                ;;
            UUID)
                u=BASH_REMATCH[2]
                ;;
        esac
    done
    if [[ -n $uuid ]]; then
        install_info "Deleting HDD $vdi ($uuid)"
        VBoxManage closemedium disk "$uuid" --delete
    fi
}

vagrant_up_main() {
    local host=${1:-v.bivio.biz}
    local ip=$2
    local base=${host%%.*}
    if [[ -z $ip ]]; then
        ip=$(dig +short "$host")
        if [[ -z $ip ]]; then
            install_err "$host: host not found and IP address not supplied"
        fi
    fi
    # Absolute path is necessary for comparison in vagrant_up_delete_vdi
    local vdi=$PWD/$base-docker.vdi
    vagrant_up_check "$vdi"
    vagrant_up_vagrantfile "$host" "$ip" "$vdi"
    vagrant up
}

vagrant_up_vagrantfile() {
    local host=$1 ip=$2 vdi=$3
    cat > Vagrantfile <<EOF
Vagrant.configure("2") do |config|
    config.vm.box = "centos/7"
    config.vm.hostname = "$host"
    config.vm.network "private_network", ip: "$ip"
    config.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--audio", "none"]
        # https://stackoverflow.com/a/36959857/3075806
        v.customize ["setextradata", :id, "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled", "0"]
        # If you see network restart issues, try this:
        # https://github.com/mitchellh/vagrant/issues/8373
        # v.customize ["modifyvm", :id, "--nictype1", "virtio"]
        #
        # Depends on host configuration
        # v.memory = 8192
        # v.cpus = 4
    end

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

    config.ssh.forward_x11 = false

    # don't need vbguest if using nfs
    if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
    end
    # Mac OS X needs version 4
    config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["rw", "vers=3", "tcp", "nolock", "fsc", "actimeo=2"]
end
EOF
}

vagrant_up_main "${install_extra_args[@]}"

#!/bin/bash
#
# Create a Centos or Fedora VirtualBox with guest additions
#
# Usage: curl radia.run | bash -s vagrant-up centos|fedora [guest-name:v.radia.run [guest-ip:10.10.10.10]]
#
set -euo pipefail

_vagrant_dev_update_tgz_base=vagrant-dev-update.tgz
_vagrant_dev_update_tgz_path=/vagrant/$_vagrant_dev_update_tgz_base
_vagrant_dev_host_os=$install_os_release_id
_vagrant_dev_have_sudo=

vagrant_dev_box_add() {
    # Returns: $box
    box=$1
    declare provider=virtualbox
    if [[ $_vagrant_dev_host_os == ubuntu ]]; then
        provider=libvirt
    fi
    if [[ ${vagrant_dev_box:-} ]]; then
        box=$vagrant_dev_box
    elif [[ $box =~ fedora ]]; then
        if [[ $box == fedora ]]; then
            if [[ $_vagrant_dev_host_os == ubuntu ]]; then
                box=generic/fedora$install_version_fedora
            else
                box=fedora/$install_version_fedora-cloud-base
            fi
        fi
    elif [[ $box == centos ]]; then
        if [[ $_vagrant_dev_host_os == ubuntu ]]; then
            box=generic/centos$install_version_centos
        else
            box=centos/$install_version_centos
        fi
    fi
    if vagrant box list | grep "$box" >& /dev/null; then
        vagrant box update --box "$box"
    elif [[ $box == fedora/32-cloud-base ]]; then
        vagrant box add https://depot.radiasoft.org/foss/fedora32-box.json
    else
        vagrant box add --provider $provider "$box"
    fi
}

vagrant_dev_first_up() {
    declare os="$1"
    declare host="$2"
    declare ip="$3"
    if [[ ! ${vagrant_dev_no_vbguest:+1} ||  ! ${vagrant_dev_no_mounts:+1} && ${vagrant_dev_provision_eth1:+1} ]]; then
        vagrant_dev_vagrantfile "$os" "$host" "$ip" 1
        vagrant up
        vagrant ssh <<'EOF'
sudo yum install -q -y kernel kernel-devel kernel-headers kernel-tools perl
EOF
        vagrant halt
    fi
}

vagrant_dev_ignore_git_dir_ownership() {
    declare os="$1"
    if [[ ! ${vagrant_dev_no_nfs_src:+1} && $os =~ fedora && ! $(install_version_fedora_lt_36) ]]; then
        echo 1
    fi
}

vagrant_dev_ip() {
    declare host=$1
    declare i=$(dig +short "$host" 2>/dev/null || true)
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
    vagrant_dev_prepare_sudo
    if [[ ! -r /etc/exports ]]; then
        sudo touch /etc/exports
        # vagrant requires /etc/exports readable by an ordinary user
        sudo chmod 644 /etc/exports
    fi
}

vagrant_dev_main() {
    declare f os= host= ip= vagrant_dev_is_update=
    for a in "$@"; do
        case $a in
            fedora*|centos*)
                os=$a
                ;;
            [1-9]*)
                ip=$a
                ;;
            update)
                vagrant_dev_is_update=1
                ;;
            v|v[1-9]|*.radia.run)
                host=$a
                ;;
            *)
                install_err "invalid arg=$a
expects: fedora|centos[/<version>], <ip address>, update, v[1-9].radia.run"
        esac
    done
    if [[ ! $os ]]; then
        install_err 'usage: radia_run vagrant-dev fedora|centos [host|ip] [update]'
    fi
    if [[ ! $host ]]; then
        if [[ ! $PWD =~ /(v[2-9]?)$ ]]; then
            install_err 'either specify a host or run from directory named v, v2, v3, ..., v9'
        fi
        host=${BASH_REMATCH[1]}
    fi
    declare base=${host%%.*}
    if [[ $base == $host ]]; then
        host=$host.radia.run
    fi
    # vbguest is pretty broken so we are defaulting to off for now
    vagrant_dev_no_vbguest=${vagrant_dev_no_vbguest-1}
    if [[ ${vagrant_dev_barebones:+1} ]]; then
        # allow individual overrides
        vagrant_dev_no_dev_env=${vagrant_dev_no_dev_env-1}
        vagrant_dev_no_mounts=${vagrant_dev_no_mounts-1}
        vagrant_dev_no_nfs_src=${vagrant_dev_no_nfs_src-1}
        vagrant_dev_no_vbguest=${vagrant_dev_no_vbguest-1}
    fi
    # Mounts only really work on Darwin for now
    if [[ ! ${vagrant_dev_no_mounts+1} && $_vagrant_dev_host_os != darwin ]]; then
        vagrant_dev_no_mounts=1
        vagrant_dev_no_vbguest=${vagrant_dev_no_vbguest-1}
    fi
    if [[ ! ${vagrant_dev_no_nfs_src+1} && $os =~ centos ]]; then
        vagrant_dev_no_nfs_src=1
    fi
#TODO(robnagler) handle fedora/<version> syntax
    if [[ ! ${vagrant_dev_provision_eth1+1} && $os =~ fedora && ! $(install_version_fedora_lt_36) ]]; then
        vagrant_dev_no_vbguest=${vagrant_dev_no_vbguest-}
        # Vagrant doesn't handle NetworkManager correctly so must handle ourselves
        # https://github.com/hashicorp/vagrant/issues/12762
        vagrant_dev_provision_eth1=1
    fi
    if [[ $_vagrant_dev_host_os == ubuntu ]]; then
        # libvirt has no vbguest.
        vagrant_dev_no_mounts=1
        vagrant_dev_no_nfs_src=1
        vagrant_dev_no_vbguest=1
    fi
    if [[ ! $ip ]]; then
        ip=$(vagrant_dev_ip "$host")
    fi
    vagrant_dev_prepare_host
    vagrant_dev_init_nfs
    vagrant_dev_prepare
    vagrant_dev_first_up "$os" "$host" "$ip"
    vagrant_dev_vagrantfile "$os" "$host" "$ip" ''
    vagrant up
    if [[ ${vagrant_dev_no_dev_env:+1} ]]; then
        return
    fi
    declare f
    for f in ~/.gitconfig ~/.netrc; do
        if [[ -r $f ]]; then
            vagrant ssh -c "install -m 600 /dev/stdin $(basename $f)" < "$f" >& /dev/null
        fi
    done
    # file:// urls don't work inside the VM
    if [[ $install_server =~ ^file: ]]; then
        declare install_server=
    fi
    vagrant ssh <<EOF
$(install_vars_export)
curl $(install_depot_server)/index.sh | \
  bivio_home_env_ignore_git_dir_ownership=$(vagrant_dev_ignore_git_dir_ownership $os) \
  bash -s redhat-dev
EOF
    vagrant_dev_post_install
}

vagrant_dev_mounts() {
    declare first="${1:+1}"
    if [[ ${vagrant_dev_no_mounts:+1} ]]; then
        echo 'config.vm.synced_folder ".", "/vagrant", disabled: true'
        return
    fi
    declare d=false
    if [[ $first ]]; then
        d=true
    fi
    # Have to use proto=tcp otherwise mount defaults to udp which doesn't work in f36
    declare f=' type: "nfs", mount_options: ["nolock", "fsc", "actimeo=2", "proto=tcp"], nfs_udp: false, disabled: '"$d"
    declare res=( 'config.vm.synced_folder ".", "/vagrant",'"$f" )
    if [[ ! ${vagrant_dev_no_nfs_src:+1} ]]; then
        mkdir -p "$HOME/src"
        res+=( 'config.vm.synced_folder "'"$HOME/src"'", "/home/vagrant/src",'"$f" )
    fi
    declare IFS='
    '
    echo "${res[*]}"
}

vagrant_dev_plugins() {
    declare x=()
    if [[ ! ${vagrant_dev_no_vbguest:+1} ]]; then
        x+=( vagrant-vbguest )
    fi
    if [[ ! ${x[@]+1} ]]; then
        return
    fi
    declare plugins=$(vagrant plugin list)
    declare p op
    for p in "${x[@]}"; do
        op=install
        if [[ $plugins =~ $p ]]; then
            op=update
        fi
        vagrant plugin "$op" "$p"
    done
}

vagrant_dev_post_install() {
    if [[ ${vagrant_dev_post_install_repo:-} ]]; then
        vagrant ssh <<EOF
$(install_vars_export)
curl $(install_depot_server)/index.sh | bash -s $vagrant_dev_post_install_repo
EOF
    fi
    if [[ ! $vagrant_dev_is_update ]]; then
        return
    fi
    # if this fails, we still want to remove the tar file
    vagrant ssh <<EOF || true
$(install_vars_export)
source ~/.bashrc
tar xpzf $_vagrant_dev_update_tgz_path
if [[ -f /vagrant/radia-run.sh ]]; then
    source /vagrant/radia-run.sh
fi
EOF
    rm -f "$_vagrant_dev_update_tgz_base"
}

vagrant_dev_prepare() {
    if [[ ! $(type -t vagrant) ]]; then
        install_err 'vagrant not installed. Please visit to install:

http://vagrantup.com'
    fi
    vagrant_dev_pre_install
    if [[ -d .vagrant ]]; then
        declare s=$(vagrant status 2>&1 || true)
        declare re=' not created |machine is required to run'
        if [[ ! $s =~ $re ]]; then
            install_err 'vagrant machine exists. Please run: vagrant destroy -f'
        fi
    fi
    vagrant_dev_plugins
}

vagrant_dev_prepare_host() {
    if [[ $_vagrant_dev_host_os != darwin ]]; then
        return
    fi
    declare f=/etc/vbox/networks.conf
    if [[ -r $f ]]; then
        return
    fi
    vagrant_dev_prepare_sudo
    sudo mkdir -p -m 0755 "$(dirname "$f")"
    echo '* 0.0.0.0/0 ::/0' | sudo dd of="$f"
    sudo chmod 644 "$f"
}

vagrant_dev_prepare_sudo() {
    if [[ ${_vagrant_dev_have_sudo:-} ]]; then
        return
    fi
    install_msg 'We need access to sudo on your Mac to configure virtualbox'
    if ! sudo true; then
        install_err 'must have access to sudo'
    fi
    _vagrant_dev_have_sudo=1
}

vagrant_dev_pre_install() {
    if [[ ! $vagrant_dev_is_update ]]; then
        return
    fi
    # if the file is there, then assume aborted update
    if [[ ! -r $_vagrant_dev_update_tgz_base ]]; then
        declare s=$(vagrant status --machine-readable 2>&1 || true)
        if [[ ! $s =~ state,running ]]; then
            install_err 'For updates, VM must be running; boot and try again'
        fi
        (cat <<EOF1; cat <<'EOF2'; cat <<EOF3) | vagrant ssh
$(install_vars_export)
EOF1
source ~/.bashrc
set -euo pipefail
if [[ -d src/radiasoft ]]; then
    e=
    cd src/radiasoft
    for f in */.git; do
        f=$(dirname "$f")
        cd "$f"
        s=$(git status --short)
        if [[ $s != '' ]]; then
            e+="
    $PWD
    $s"
        fi
        cd ..
    done
    cd ../..
    if [[ $e ]]; then
        echo "git directories in ~/src/radiasoft have non-empty status:$e
"
        exit 1
    fi
fi
EOF2
tar czf $_vagrant_dev_update_tgz_path --ignore-failed-read .netrc .gitconfig .bash_history .{post,pre}_bivio_bashrc .emacs.d/lisp/{post,pre}-bivio-init.el .ssh/{id_*,config} bconf.d >& /dev/null
EOF3
        if [[ ! -r $_vagrant_dev_update_tgz_base ]]; then
            install_err "failed to create $_vagrant_dev_update_tgz_base; no NFS setup or git status?"
        fi
    fi
    vagrant destroy -f
}

vagrant_dev_vagrantfile() {
    declare os=$1 host=$2 ip=$3 first=$4
    declare vbguest='' timesync=''
    if [[ ${vagrant_dev_no_vbguest:+1} ]]; then
        vbguest='if Vagrant.has_plugin? "vagrant-vbguest"
      config.vbguest.no_install  = true
      config.vbguest.auto_update = false
      config.vbguest.no_remote   = true
      # avoids a warning even though we may have nfs later on
      config.vm.synced_folder ".", "/vagrant", type: "virtualbox", disabled: true
    end'
    else
        if [[ $first ]]; then
            vbguest='config.vbguest.auto_update = false'
        else
            # https://medium.com/carwow-product-engineering/time-sync-problems-with-vagrant-and-virtualbox-383ab77b6231
            timesync='v.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 5000]'
        fi
    fi
    declare macos_fixes=
    if [[ $_vagrant_dev_host_os == darwin ]]; then
        macos_fixes='v.customize [
            "modifyvm", :id,
                # Fix Mac thunderbolt issue
                "--audio", "none",
                # https://www.dbarj.com.br/en/2017/11/fixing-virtualbox-crashing-macos-on-high-load-kernel-panic/
                # https://stackoverflow.com/a/31425419
                "--paravirtprovider", "none",
        ]'
    fi
    # vagrant_dev_box_add returns in box
    declare box
    vagrant_dev_box_add "$os"
    declare mounts="$(vagrant_dev_mounts $first)"
    if [[ $_vagrant_dev_host_os == ubuntu ]]; then
        declare provider=$(cat <<'EOF'
    config.vm.provider :libvirt do |v|
EOF
)
    else
        declare provider=$(cat <<EOF
    config.vm.provider :virtualbox do |v|
        ${timesync}
        ${macos_fixes}
        # https://stackoverflow.com/a/36959857/3075806
        v.customize ["setextradata", :id, "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled", "0"]
        # If you see network restart or performance issues, try this:
        # https://github.com/mitchellh/vagrant/issues/8373
        # v.customize ["modifyvm", :id, "--nictype1", "virtio"]
        # https://github.com/radiasoft/download/issues/104
        v.customize ["modifyvm", :id, "--ioapic", "on"]
EOF
)
    fi
    declare eth1=
    if [[ ${vagrant_dev_provision_eth1:-} ]]; then
        eth1="nmcli con add con-name eth1 ifname eth1 type ethernet ip4 $ip/24 && nmcli con up eth1"
    fi
    cat > Vagrantfile <<EOF
# -*-ruby-*-
Vagrant.configure("2") do |config|
    config.vm.box = "$box"
    config.vm.hostname = "$host"
    config.vm.network "private_network", ip: "$ip"
${provider}
        # 8192 needed for compiling some the larger codes
        v.memory = ${vagrant_dev_memory:-8192}
        v.cpus = ${vagrant_dev_cpus:-4}
    end
    config.ssh.forward_x11 = false
    ${vbguest}
    # https://stackoverflow.com/a/33137719/3075806
    # Undo mapping of hostname to 127.0.?.1
    config.vm.provision "shell", inline: <<-'END'
        sed -i '/127.0.*$host/d' /etc/hosts
        $eth1
    END
    ${mounts}
end
EOF
}

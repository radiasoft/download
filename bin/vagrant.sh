#!/bin/bash
#
# Install vagrant
#
vagrant_boot() {
    local cmd=$(basename "$install_container")
    case $install_container in
        */sirepo)
            cat > "$cmd" <<EOF
#!/bin/bash
echo '

Point your browser to:

http://127.0.0.1:$vagrant_port/srw

'
exec ./.bivio_vagrant_ssh sirepo service http --port $vagrant_port --run-dir /vagrant
EOF
            ;;
        *)
            cat > "$cmd" <<'EOF'
#!/bin/bash
exec ./.bivio_vagrant_ssh "$@"
EOF
    esac
    chmod +x "$cmd"
    echo "Making sure your $install_container virtual machine is running..."
    ./.bivio_vagrant_ssh echo Done
    echo "Running ./$cmd"
    exec "./$cmd"
}

vagrant_check() {
    # A little sanity check
    if [[ $(ls .vagrant/machines/default/virtualbox 2>/dev/null) ]]; then
        err 'Virtual machine exists, remove with: vagrant destroy -f'
    fi
}

vagrant_download_ssh() {
    curl -s -S -L https://raw.githubusercontent.com/biviosoftware/home-env/master/bin/bivio_vagrant_ssh > .bivio_vagrant_ssh
    chmod +x .bivio_vagrant_ssh
}

vagrant_file() {
    # Boot without synced folders, because guest additions may not be right.
    # Don't insert the private key yet either.
    local host=$(basename "$install_container")
    cat > Vagrantfile<<EOF
# -*- mode: ruby -*-
Vagrant.configure(2) do |config|
    config.vm.box = "$install_container"
    config.vm.hostname = "$host"
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.ssh.insert_key = false
    config.ssh.forward_x11 = false
end
EOF
    # Too bad "update" doesn't just "add" if not installed...
    if vagrant box list | grep -s -q "^$install_container[[:space:]]"; then
        vagrant box update || true
    else
        vagrant box add "$install_container"
    fi
    # The final Vagrantfile, which will be "fixed up" by bivio_vagrant_ssh
    local forward=
    if [[ $vagrant_port ]]; then
        forward="config.vm.network \"forwarded_port\", guest: $vagrant_port, host: $vagrant_port"
    fi
    cat > Vagrantfile-actual <<EOF
# -*- mode: ruby -*-
Vagrant.configure(2) do |config|
    config.vm.box = "$install_container"
    config.vm.hostname = "$host"
    config.ssh.forward_x11 = true
    ${forward}
end
EOF
    # used by bivio_vagrant_ssh first time
    export vagrantfile_fixup='mv -f Vagrantfile-actual Vagrantfile'
}

vagrant_main() {
    vagrant_check
    vagrant_vars
    vagrant_download_ssh
    vagrant_file
    vagrant_boot
}

vagrant_vars() {
    case $install_container in
        */sirepo)
            vagrant_port=8000
            ;;
        *)
            vagrant_port=
            ;;
    esac
}

set -e
vagrant_main

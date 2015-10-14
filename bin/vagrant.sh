#!/bin/bash
#
# Install vagrant
#
vagrant_boot() {
    local cmd=$(basename "$install_image")
    case $install_image in
        */sirepo)
            cat > "$cmd" <<EOF
#!/bin/bash
echo '

Point your browser to:

http://127.0.0.1:$install_forward_port/srw

'
exec ./.bivio_vagrant_ssh sirepo service http --port $install_forward_port --run-dir /vagrant
EOF
            ;;
        *)
            cat > "$cmd" <<'EOF'
#!/bin/bash
exec ./.bivio_vagrant_ssh "$@"
EOF
    esac
    chmod +x "$cmd"
    echo "Making sure your $install_image virtual machine is running..."
    ./.bivio_vagrant_ssh echo Done
    echo "Starting ./$cmd"
    exec "./$cmd"
}

vagrant_download_ssh() {
    install_download https://raw.githubusercontent.com/biviosoftware/home-env/master/bin/bivio_vagrant_ssh > .bivio_vagrant_ssh
    chmod +x .bivio_vagrant_ssh
}

vagrant_file() {
    # Boot without synced folders, because guest additions may not be right.
    # Don't insert the private key yet either.
    local host=$(basename "$install_image")
    cat > Vagrantfile<<EOF
# -*- mode: ruby -*-
Vagrant.configure(2) do |config|
    config.vm.box = "$install_image"
    config.vm.hostname = "$host"
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.ssh.insert_key = false
    config.ssh.forward_x11 = false
end
EOF
    # Too bad "update" doesn't just "add" if not installed...
    if vagrant box list | grep -s -q "^$install_image[[:space:]]"; then
        vagrant box update || true
    else
        vagrant box add "$install_image"
    fi
    # The final Vagrantfile, which will be "fixed up" by bivio_vagrant_ssh
    local forward=
    if [[ $install_forward_port ]]; then
        forward="config.vm.network \"forwarded_port\", guest: $install_forward_port, host: $install_forward_port"
    fi
    cat > Vagrantfile-actual <<EOF
# -*- mode: ruby -*-
Vagrant.configure(2) do |config|
    config.vm.box = "$install_image"
    config.vm.hostname = "$host"
    config.ssh.forward_x11 = true
    ${forward}
end
EOF
    # used by bivio_vagrant_ssh first time
    export vagrantfile_fixup='mv -f Vagrantfile-actual Vagrantfile'
}

vagrant_main() {
    vagrant_download_ssh
    vagrant_file
    vagrant_boot
}

vagrant_main

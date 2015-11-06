#!/bin/bash
#
# Install vagrant
#
vagrant_boot() {
    vagrant_script
    install_info "Booting $install_image virtual machine"
    install_exec ./.bivio_vagrant_ssh echo Done
    install_info "Starting ./$vagrant_script"
    exec "./$vagrant_script"
}

vagrant_download_ssh() {
    install_download https://raw.githubusercontent.com/biviosoftware/home-env/master/bin/bivio_vagrant_ssh > .bivio_vagrant_ssh
    chmod +x .bivio_vagrant_ssh
}

vagrant_file() {
    # Boot without synced folders, because guest additions may not be right.
    # Don't insert the private key yet either.
    install_log Creating Vagrantfile
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
        install_info "Updating $install_image"
        install_exec vagrant box update
    else
        install_info "Downloading $install_image"
        install_exec vagrant box add "$install_image"
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
    install_info 'Installing with vagrant'
    vagrant_download_ssh
    vagrant_file
    vagrant_boot
}

vagrant_script() {
    vagrant_script=$(basename "$install_image")
    install_log Creating "$vagrant_script"
    case $install_image in
        */radtrack)
            cat > "$vagrant_script" <<EOF
#!/bin/bash
exec ./.bivio_vagrant_ssh radtrack-on-vagrant
EOF
            ;;
        */sirepo)
            cat > "$vagrant_script" <<EOF
#!/bin/bash
echo '

Point your browser to:

http://127.0.0.1:$install_forward_port/srw

'
exec ./.bivio_vagrant_ssh sirepo service http --port $install_forward_port --run-dir /vagrant
EOF
            ;;
        *)
            cat > "$vagrant_script" <<'EOF'
#!/bin/bash
exec ./.bivio_vagrant_ssh "$@"
EOF
    esac
    chmod +x "$vagrant_script"
}

vagrant_main

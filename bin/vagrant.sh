#!/bin/bash
#
# Install vagrant
#
vagrant_boot() {
    install_info "Booting $install_image virtual machine"
    install_exec ./.bivio_vagrant_ssh echo Done
    install_radia_run
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
        if [[ -z $install_test ]]; then
            install_exec vagrant box update
        fi
    else
        install_info "Downloading $install_image"
        install_exec vagrant box add "$install_image"
    fi
    # The final Vagrantfile, which will be "fixed up" by bivio_vagrant_ssh
    local forward=()
    if [[ -n $install_x11 ]]; then
        forward+=('    config.ssh.forward_x11 = true
')
    fi
    if [[ -n $install_port ]]; then
        forward+=("    config.vm.network \"forwarded_port\", guest: $install_port, host: $install_port
")
    fi
    cat > Vagrantfile-actual <<EOF
# -*- mode: ruby -*-
Vagrant.configure(2) do |config|
    config.vm.box = "$install_image"
    config.vm.hostname = "$host"
${forward[@]}end
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

#
# Vagrant radia-run-* functions: See install_radia_run
# Inline hear so syntax checked and easier to edit.
#
radia_run_main() {
    radia_run_exec ./.bivio_vagrant_ssh
}

#!/bin/bash
#
# Install Docker image and start
#
docker_main() {
    install_info 'Installing with docker'
    docker_run=$(install_download docker-run.sh)
    #TODO(robnagler) add install_channel
    install_info "Downloading $install_image"
    install_exec docker pull "$install_image"
    docker_script
    install_info "Starting ./$docker_script"
    exec "./$docker_script"
}

docker_script() {
    docker_script=$(basename "$install_image")
    install_log "Creating $docker_script"
    local prompt=
    local cmd=bash
    if [[ $install_image =~ /sirepo$ ]]; then
        cmd="sirepo service http --port $install_forward_port --run-dir /vagrant"
        prompt="
Point your browser to:

http://127.0.0.1:$install_forward_port/srw
"
    fi
    cat > "$docker_script" <<EOF
#!/bin/bash
#
# Invoke docker run on $cmd
#
set -x
docker_cmd='$cmd'
docker_container=\$(id -u -n)-\$(basename '$install_image')
docker_image='$install_image'
docker_port='$install_forward_port'
docker_prompt='$prompt'

$(declare -f install_msg)
$(declare -f install_err)

$docker_run
EOF
    chmod +x "$docker_script"
}

docker_main

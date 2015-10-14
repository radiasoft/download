#!/bin/bash
#
# Install Docker image and start
#
docker_download_run() {
    docker_run=$(curl -s -S -L "$install_run/docker-run.sh")
    if [[ ! $docker_run =~ ^#!/bin/bash ]]; then
        install_err 'Unable to download docker-run.sh'
    fi
}

docker_main() {
    docker_download_run
    docker_script
    echo "Starting ./$docker_script"
    exec "./$docker_script"
}

docker_script() {
    docker_script=$(basename "$install_image")
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
docker_cmd='$cmd'
docker_container=$(id -u -n)-$(basename '$docker_image')
docker_image='$install_image'
docker_port='$install_forward_port'
docker_prompt='$prompt'

$docker_run
EOF
    chmod +x "$docker_script"
}

docker_main

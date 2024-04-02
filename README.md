# Installing RadiaSoft Docker Containers

RadiaSoft provides Docker containers for our applications
and other open source physics codes.

## Automatic Installer (Mac, Linux, and Cygwin)

We support automatic installation of our Docker images on Unix-like
systems with `curl` installers. You will need to
[Install Docker](#install-docker) before proceeding with these
instructions.

### Sirepo

Most people use Sirepo in the cloud at [sirepo.com](https://sirepo.com).
However, to run Sirepo locally, you can use this command:

```sh
$ curl https://sirepo.run | bash
```

### Jupyter

We run a public JupyterHub at [jupyter.radiasoft.org](https://jupyter.radiasoft.org).
You can also run our Jupyter Docker image with the same
[pre-installed of particle accelerator and beam simulation codes](https://github.com/radiasoft/container-beamsim)
on your desktop with:

```sh
$ curl https://jupyter.run | bash
```

### Other images and installers

To run a different installer, you simply pass it as an argument to bash.
For example, to run the `vagrant-sirepo-dev` installer, which installs
a Vagrant/VirtualBox development environment for Sirepo, just type:

```sh
$ curl https://radia.run | bash -s vagrant-sirepo-dev
```

### `radia_run` command

If you use RadiaSoft's home environment (aka. dot files), you get the
`radia_run` command, which makes it easier to run an installer, e.g.

```sh
$ radia_run vagrant-sirepo-dev
```

It is more convenient and also allows you to set
[an `install_server`, which is helpful for developing](#development-notes).

## Quick Start if you already know Docker

If you already have [Docker installed](#requirements), you can run Sirepo with:

```sh
docker run -v $PWD:/sirepo -p 8000:8000 radiasoft/sirepo
```

If you would like to run our beamsim jupyter notebook server, do:

```sh
docker run -v $PWD:/home/vagrant/jupyter -p 8888:8888 radiasoft/beamsim-jupyter
```

## Install Docker

Before installing RadiaSoft containers, you'll need to install Docker:

* [Mac OS X](https://docs.docker.com/docker-for-mac/install/)

* [Windows](https://docs.docker.com/docker-for-windows/install/)

* [Linux](https://docs.docker.com/engine/installation/#/on-linux)

## Startup Command

The output of the curl will also tell you how to connect to the server
and/or login to the container. It will create a command in the directory
with the same name as the container, which you can use to restart the
container. For example, to restart sirepo, just type:

```sh
$ ./radia-run

Point your browser to:

http://127.0.0.1:8000

 * Running on http://0.0.0.0:8000/ (Press CTRL+C to quit)
 * Restarting with stat
```

## Development Notes

To add a downloader, just add to `installers` directory. Make
sure the name doesn't conflict with obvious words like `verbose`,
`debug`, `alpha`, `beta`, etc. The command line is just a list
of keywords that gets recognized by the installer.

You can also specify a file `radiasoft-download.sh` in any repo
directory. The installer will go to that github repo for now.

To run installers, the root of the tree is `~/src` so this file would
be `~/src/radiasoft/download/README.md`. If your home directory is not
set up this way, the following will not work.

Installers can be run with a Python's http.server as follows:

```sh
bash etc/dev-server.sh
```

This command starts the http.server and outputs instructions on how to
run installers in the local dev environment.

### Serverless testing

Many of the installers can be tested with:

```sh
export install_server=file://$HOME/src
curl https://radia.run | install_debug=1 bash -s nersc-sirepo-update alpha
```

### install.sh testing

To test with a github install_server, that is, to test install.sh
itself, you an run it this way:

```sh
bash -s debug some/repo < download/bin/install.sh
```

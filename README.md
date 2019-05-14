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
$ curl sirepo.run | bash
```

### Jupyter

We run a public JupyterHub at [jupyter.radiasoft.org](https://jupyter.radiasoft.org).
You can also run our Jupyter Docker image with the same
[pre-installed of particle accelerator and beam simulation codes](https://github.com/radiasoft/container-beamsim)
on your desktop with:

```sh
$ curl jupyter.run | bash
```

### Other images and installers

To run a different installer, you simply pass it as an argument to bash.
For example, to run the `vagrant-sirepo-dev` installer, which installs
a Vagrant/VirtualBox development environment for Sirepo, just type:

```sh
$ curl radia.run | bash -s vagrant-sirepo-dev
```

### `radia_run` command

If you use RadiaSoft's home environment (aka. dot files), you get the
`radia_run` command, which makes it easier to run an installer, e.g.

```sh
$ radia_run vagrant-sirepo-dev
```

This runs over TLS (https) so it is more secure. It also allows you to
set [an `install_server`, which is helpful for developing](#development-notes).

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

To test the installer, you can set:

```sh
cd ~/src
rm -f index.sh
ln -s -r radiasoft/download/bin/index.sh .
python -m SimpleHTTPServer 1313
# another window
export install_server=http://$(dig $(hostname -f) +short):1313
z# assumes radia_run: curl $install_server/index.sh | bash -s unit-test arg1
radia_run unit-test arg1
```

This will set the `$install_url` to `file://$HOME/src`.

You can also pass `debug` to get more output.

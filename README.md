### Installing RadiaSoft Containers and VMs

RadiaSoft provides Docker containers and VirtualBox virtual machines (VMs)
for our applications and other open source physics codes. Since the
VMs and containers are
[built with the same code](https://github.com/radiasoft/containers),
we just call them containers here.

At this time, all of our images are based on
the [official Docker](https://hub.docker.com/_/fedora/)
and [Hansode Vagrant](https://vagrantcloud.com/hansode/boxes/fedora-21-server-x86_64)
Fedora 21 images.

Here is the our list of containers supported by this automated downloader:

* [radiasoft/beamsim](https://github.com/radiasoft/containers/tree/master/radiasoft/beamsim)
  is a physics container for particle accelerator and free electron laser (FEL) simulations.

* [radiasoft/python2](https://github.com/radiasoft/containers/tree/master/radiasoft/python2)
  is a basic Python2 (currently 2.7.10) pyenv with matplotlib and numpy.

* [radiasoft/sirepo](https://github.com/radiasoft/containers/tree/master/radiasoft/sirepo)
  is an web application to simplify the execution of scientific codes.

We also have a separate (older) downloader for our
[RadTrack](https://github.com/radiasoft/radtrack) container image:

* [radiasoft/radtrack](https://github.com/radiasoft/radtrack-installer/tree/master/darwin)
  is a desktop (Qt) application to simplify execution of accelerator codes.

#### Requirements

Before installing RadiaSoft containers, you must have
[Vagrant](https://www.vagrantup.com/downloads.html) running
on your Windows PC or Mac
with a [VirtualBox provider](https://docs.vagrantup.com/v2/virtualbox).
We provide a little help below on installing Vagrant on the
[Mac](https://github.com/radiasoft/download/blob/master/README.md#installing-vagrant-on-mac-os-x)
and
[Windows](https://github.com/radiasoft/download/blob/master/README.md#installing-vagrant-on-windows)


On Linux, you can use
[Docker](http://docs.docker.com/engine/installation/), which
is lighter weight than Vagrant. We recommend
[running Docker as a trusted, non-root user](http://askubuntu.com/questions/477551/how-can-i-use-docker-without-sudo).
By trusted, we mean a user who already has `sudo` privileges. As noted (in the
[previous link](http://askubuntu.com/questions/477551/how-can-i-use-docker-without-sudo))),
there are [privilege escalation attacks](http://docs.docker.com/engine/articles/security/#docker-daemon-attack-surface)
with Docker so don't give the privileges to untrusted users.

#### Curl Installer (Mac, Linux, and Cygwin)

The most straightforward way to install a RadiaSoft container image, e.g.
[sirepo](https://github.com/radiasoft/sirepo), is to run our automated
installer in an empty. For example,

```
mkdir sirepo
cd sirepo
curl radiasoft.download | bash
```

This will install, configure the image named by the current
directory, and run it from the current directory. The image name
is taken from the directory name.

You can also be explicit and request a different container:

```
mkdir foobar
cd foobar
curl radiasoft.download | bash -s sirepo
```

There are a few other options (words) which may be useful, e.g.

```
curl radiasoft.download | bash -s sirepo verbose
```

You can also be explicit about which type of image you'd like:

```
curl radiasoft.download | bash -s sirepo vagrant
```

The order of the optional keywords after the `bash -s` do not matter.

#### Startup Command

The output of the curl will also tell you how to connect to the server
and/or login to the container. It will create a command in the directory
with the same name as the container, which you can use to restart the
container. For example, to restart sirepo, just type:

```bash
$ ./sirepo

Point your browser to:

http://127.0.0.1:8000/srw

 * Running on http://0.0.0.0:8000/ (Press CTRL+C to quit)
 * Restarting with stat
```

#### Starting Vagrant Manually

On Windows, you will have to start your Vagrant VM manually. You can
run these same commands on Linux or the Mac, but it's more work,
especially since there's no automated way to bind ports and volumes.

It makes sense to do this from a clean directory:

```cmd
mkdir vagrant
cd vagrant
```

You could use `vagrant init`, but it will run into problems with guest
additions. We recommend you create the `Vagrantfile` manually in the
directory you just created with a text editor:

```ruby
Vagrant.configure(2) do |config|
  config.vm.box = "radiasoft/beamsim"
  config.vm.hostname = "rs"
  # If you need X11, uncomment this line:
  # config.ssh.forward_x11 = true
  config.vm.synced_folder ".", "/vagrant", disabled: true
end
```

Then download and boot the virtual machine (VM) image (e.g. `radiasoft/beamsim`)
from the Vagrant repository with the following command:

```cmd
vagrant up
```

You'll need to update the "guest additions" for VirtualBox. Get the version
from VirtualBox. You can do this by starting the GUI and looking under the
"About" menu, or you might be able to run `VBoxManage` from the command prompt:

```cmd
VBoxManage --version
4.3.28r100309
```

The version is everything before the `r`. In this example, the value
is `4.3.28`. You will replace `YOUR-VERSION-HERE` in the following example
with your version number (e.g. `4.3.28`) when you execute the following
sequence of commands:

```bash
vagrant ssh -c "sudo su -"
v=YOUR-VERSION-HERE
curl -L -O http://download.virtualbox.org/virtualbox/$v/VBoxGuestAdditions_$v.iso
mount -t iso9660 -o loop VBoxGuestAdditions_$v.iso /mnt
sh /mnt/VBoxLinuxAdditions.run < /dev/null
umount /mnt
rm -f VBoxGuestAdditions_$v.iso
exit
```

Once the install completes, edit the `Vagrantfile` again, removing this line:

```ruby
config.vm.synced_folder ".", "/vagrant", disabled: true
```

If you are running Sirepo, see the instructions below.

In your shell/command prompt, type:

```cmd
vagrant reload
```

After your VM boots, login to your VM as follows on Windows:

```cmd
REM If you need X11, uncomment this line:
REM set DISPLAY=localhost:0
vagrant ssh
```

You can also add `DISPLAY=localhost:0` to your user environment in the Control Panel
so that you don't have to type the `set` command each time.

On the Mac or Linux, you would type:

```sh
vagrant ssh
```

On the Mac, XQuartz automatically sets your `$DISPLAY` variable.

#### Running Sirepo Manually

If you are running sirepo, you'll need to add an extra line
to your `Vagrantfile` before booting the second time:

```ruby
  forward="config.vm.network \"forwarded_port\", guest: 8000, host: 8000"
```

To run sirepo, you need to:

```bash
vagrant ssh
sirepo service http --port 8000 --run-dir /vagrant
```

You can use a different port than `8000`, just replace the values above.

The simulation files will show up on your Mac or PC in the directory
from which `vagrant ssh` was run.

#### Installing Vagrant on Mac OS X

You need to download and install the following (in order):

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/downloads.html)

If you want to run X11 applications (e.g. RadTrack), you will need to
install an X11 server:

* [XQuartz](http://www.xquartz.org)

#### Installing Vagrant on Windows

You need to download and install the following (in order):

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [SSHWindows](http://www.mls-software.com/opensshd.html)
* [Vagrant](https://www.vagrantup.com/downloads.html)

If you want to run X11 applications (e.g. RadTrack), you will need to
install an X11 server:

* [VcXsrv](https://sourceforge.net/projects/vcxsrv/)

You'll need to reboot and start vcxsrv manually.

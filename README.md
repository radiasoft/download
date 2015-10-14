### Installing RadiaSoft Containers

The most straightforward way to install a RadiaSoft container, e.g.
[sirepo](https://github.com/radiasoft/sirepo), is to run our automated
installer in an empty. For example,

```
mkdir sirepo
cd sirepo
curl radiasoft.download | bash
```

This will install, configure the container, and run it from the current
directory. The container name is taken from the base directory. You can also:

```
mkdir foobar
cd foobar
curl radiasoft.download | bash -s sirepo
```

### Requirements

If you are running on a Mac, you will need to install
[Vagrant](https://docs.vagrantup.com/v2/installation/)
from [this DMG](https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.4.dmg).

If you are running on Linux, you can either install
[Docker](https://docs.docker.com/installation/)
or [Vagrant](http://www.vagrantup.com/downloads).

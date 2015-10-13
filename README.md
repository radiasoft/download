### Installing RadiaSoft Containers

The most straightforward way to install a RadiaSoft container, e.g.
[sirepo](https://github.com/radiasoft/sirepo), is to run our automated
installer in an empty. For example,

```
mkdir sirepo
cd sirepo
curl radiasoft.download | bash -s sirepo
```

This will install and configure the container to run from the current
directory. You can then run the container's main program with:

```
./sirepo
```

### Requirements

If you are running on a Mac, you will need to install
[Vagrant](https://docs.vagrantup.com/v2/installation/)
from [this DMG](https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.4.dmg).

If you are running on Linux, you can either install
[Docker](https://docs.docker.com/installation/)
or [Vagrant](http://www.vagrantup.com/downloads).

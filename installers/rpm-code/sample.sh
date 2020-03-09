#!/bin/bash
# https://stackoverflow.com/questions/880227/what-is-the-minimum-i-have-to-do-to-create-an-rpm-file
# https://wiki.centos.org/HowTos/SetupRpmBuildEnvironment
mkdir -p ~/rpmbuild/{RPMS,SRPMS,BUILD,SOURCES,SPECS,tmp}
cat <<EOF >~/.rpmmacros
%_topdir   %(echo $HOME)/rpmbuild
%_tmppath  %{_topdir}/tmp
EOF
cp sample.spec ~/rpmbuild/SPECS/sample.spec
cd ~/rpmbuild
mkdir -p BUILDROOT/home/vagrant
cp --link ~/.local ~/.pyenv BUILDROOT/home/vagrant
rpmbuild --buildroot $PWD/BUILDROOT -bb SPECS/sample.spec

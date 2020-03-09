#!/bin/bash
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

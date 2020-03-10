#!/bin/bash
cat > include.txt <<EOF
$PWD/codes
EOF
cat > exclude.txt <<EOF
$PWD
EOF
cat > depends.txt <<EOF
EOF
rm -rf ~/rpmbuild ~/.rpmmacros
mkdir -p ~/rpmbuild/{RPMS,SRPMS,BUILD,SOURCES,SPECS,tmp}
cat <<EOF >~/.rpmmacros
%_topdir   %(echo $HOME)/rpmbuild
%_tmppath  %{_topdir}/tmp
EOF
perl build-rpm.PL . foo 1.1 'first line
second line' > ~/rpmbuild/SPECS/foo.spec
mkdir -p ~/rpmbuild/BUILDROOT/$PWD
cp -a --link * ~/rpmbuild/BUILDROOT/$PWD
cd ~/rpmbuild
rpmbuild --buildroot $PWD/BUILDROOT -bb SPECS/foo.spec

# Hello packaging friend!
#
# If you find yourself using this 'fpm --edit' feature frequently, it is
# a sign that fpm is missing a feature! I welcome your feature requests!
# Please visit the following URL and ask for a feature that helps you never
# need to edit this file again! :)
#   https://github.com/jordansissel/fpm/issues
# ------------------------------------------------------------------------

# Disable the stupid stuff rpm distros include in the build process by default:
#   Disable any prep shell actions. replace them with simply 'true'
%define __spec_prep_post true
%define __spec_prep_pre true
#   Disable any build shell actions. replace them with simply 'true'
%define __spec_build_post true
%define __spec_build_pre true
#   Disable any install shell actions. replace them with simply 'true'
%define __spec_install_post true
%define __spec_install_pre true
#   Disable any clean shell actions. replace them with simply 'true'
%define __spec_clean_post true
%define __spec_clean_pre true
# Disable checking for unpackaged files ?
#%undefine __check_files

# Allow building noarch packages that contain binaries
%define _binaries_in_noarch_packages_terminate_build 0

# Use md5 file digest method.
# The first macro is the one used in RPM v4.9.1.1
%define _binary_filedigest_algorithm 1
# This is the macro I find on OSX when Homebrew provides rpmbuild (rpm v5.4.14)
%define _build_binary_file_digest_algo 1

# Use gzip payload compression
%define _binary_payload w9.gzdio


Name: rscode-common-test
Version: 20200309.211226
Release: 1
Summary: no description given
AutoReqProv: no
# Seems specifying BuildRoot is required on older rpmbuild (like on CentOS 5)
# fpm passes '--define buildroot ...' on the commandline, so just reuse that.
BuildRoot: %buildroot

Prefix: /

Group: default
License: unknown
Vendor: vagrant@v.radia.run
URL: http://example.com/no-uri-given
Packager: <vagrant@v.radia.run>

%description
no description given

%prep
# noop

%build
# noop

%install
# noop

%clean
# noop




%files
%defattr(-,root,root,-)

%dir %attr(755, vagrant, vagrant) /home/vagrant/.local

%dir %attr(755, vagrant, vagrant) /home/vagrant/.local/bin

%dir %attr(755, vagrant, vagrant) /home/vagrant/.local/etc

%dir %attr(755, vagrant, vagrant) /home/vagrant/.local/etc/bashrc.d

%dir %attr(755, vagrant, vagrant) /home/vagrant/.local/include

%dir %attr(755, vagrant, vagrant) /home/vagrant/.local/lib

%dir %attr(755, vagrant, vagrant) /home/vagrant/.local/share

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/branches

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/info

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/logs

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/logs/refs

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/logs/refs/heads

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/logs/refs/remotes

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/logs/refs/remotes/origin

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/objects

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/objects/info

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/objects/pack

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/refs

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/refs/heads

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/refs/remotes

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/refs/remotes/origin

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/refs/tags

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.github

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/bin

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/cache

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/completions

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/exec

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/exec/pip-rehash

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/rehash

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/rehash/conda.d

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/rehash/source.d

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/src

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/test

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/test/libexec

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/distutils

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/cli

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel-0.33.4.dist-info

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/pkgconfig

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/share

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/share/man

%dir %attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/share/man/man1

# Reject config files already listed or parent directories, then prefix files
# with "/", then make sure paths with spaces are quoted. I hate rpm so much.
%attr(640, vagrant, vagrant) /home/vagrant/.post_bivio_bashrc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.agignore

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/HEAD

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/config

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/description

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks/applypatch-msg.sample

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks/commit-msg.sample

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks/fsmonitor-watchman.sample

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks/post-update.sample

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks/pre-applypatch.sample

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks/pre-commit.sample

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks/pre-push.sample

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks/pre-rebase.sample

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks/pre-receive.sample

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks/prepare-commit-msg.sample

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/.git/hooks/update.sample

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/index

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/info/exclude

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/logs/HEAD

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/logs/refs/heads/master

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/logs/refs/remotes/origin/HEAD

%attr(440, vagrant, vagrant) /home/vagrant/.pyenv/.git/objects/pack/pack-e462ce46b7d03af69cbee955c262e7fb0e0ec0d7.idx

%attr(440, vagrant, vagrant) /home/vagrant/.pyenv/.git/objects/pack/pack-e462ce46b7d03af69cbee955c262e7fb0e0ec0d7.pack

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/packed-refs

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/refs/heads/master

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/refs/remotes/origin/HEAD

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.git/shallow

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.github/ISSUE_TEMPLATE.md

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.github/PULL_REQUEST_TEMPLATE.md

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.gitignore

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.travis.yml

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/.vimrc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/CHANGELOG.md

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/COMMANDS.md

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/CONDUCT.md

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/LICENSE

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/Makefile

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/README.md

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/bin/pyenv

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/completions/pyenv.bash

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/completions/pyenv.fish

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/completions/pyenv.zsh

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv---version

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-commands

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-completions

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-exec

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-global

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-help

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-hooks

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-init

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-local

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-prefix

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-rehash

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-root

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-sh-rehash

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-sh-shell

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-shims

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-version

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-version-file

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-version-file-read

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-version-file-write

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-version-name

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-version-origin

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-versions

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-whence

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/libexec/pyenv-which

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/exec/pip-rehash/conda

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/exec/pip-rehash/easy_install

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/exec/pip-rehash/pip

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/exec/pip-rehash.bash

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/rehash/conda.bash

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/rehash/conda.d/.gitignore

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/rehash/conda.d/default.list

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/rehash/source.bash

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/rehash/source.d/.gitignore

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/pyenv.d/rehash/source.d/default.list

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/2to3

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/activate

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/activate.csh

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/activate.fish

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/activate.ps1

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/activate_this.py

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/easy_install

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/easy_install-2.7

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/idle

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/pip

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/pip2

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/pip2.7

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/pydoc

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/python

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/python-config

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/python2

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/python2-config

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/python2.7

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/python2.7-config

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/python2.7-gdb.py

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/smtpd.py

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/tox

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/tox-quickstart

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/virtualenv

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/shims/wheel

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/src/Makefile.in

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/src/bash.h

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/src/configure

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/src/realpath.c

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/src/shobj-conf

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/terminal_output.png

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/--version.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/commands.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/completions.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/exec.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/global.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/help.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/hooks.bats

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/test/init.bats

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/test/libexec/pyenv-echo

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/local.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/prefix.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/pyenv.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/pyenv_ext.bats

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/test/rehash.bats

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/test/run

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/shell.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/shims.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/test_helper.bash

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/version-file-read.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/version-file-write.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/version-file.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/version-name.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/version-origin.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/version.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/versions.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/whence.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/test/which.bats

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/version

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/2to3

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/easy_install

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/easy_install-2.7

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/idle

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/pip

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/pip2

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/pip2.7

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/pydoc

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/python

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/python-config

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/python2

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/python2-config

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/python2.7

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/python2.7-config

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/python2.7-gdb.py

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/smtpd.py

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/tox

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/tox-quickstart

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/bin/virtualenv

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/activate

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/activate.csh

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/activate.fish

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/activate.ps1

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/activate_this.py

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/easy_install

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/easy_install-2.7

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/pip

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/pip2

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/pip2.7

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/pydoc

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/python

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/python-config

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/python2

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/python2.7

%attr(750, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/bin/wheel

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/LICENSE.txt

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/UserDict.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/_abcoll.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/_weakrefset.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/abc.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/codecs.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/config

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/copy_reg.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/distutils/__init__.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/distutils/__init__.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/distutils/distutils.cfg

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/encodings

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/fnmatch.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/genericpath.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/lib-dynload

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/linecache.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/locale.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/no-global-site-packages.txt

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/ntpath.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/orig-prefix.txt

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/os.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/posixpath.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/re.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/easy_install.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/easy_install.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/__init__.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/__init__.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/__main__.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/__main__.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/bdist_wheel.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/bdist_wheel.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/cli/__init__.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/cli/__init__.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/cli/convert.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/cli/convert.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/cli/pack.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/cli/pack.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/cli/unpack.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/cli/unpack.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/metadata.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/metadata.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/pep425tags.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/pep425tags.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/pkginfo.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/pkginfo.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/util.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/util.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/wheelfile.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel/wheelfile.pyc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel-0.33.4.dist-info/INSTALLER

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel-0.33.4.dist-info/LICENSE.txt

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel-0.33.4.dist-info/METADATA

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel-0.33.4.dist-info/RECORD

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel-0.33.4.dist-info/WHEEL

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel-0.33.4.dist-info/entry_points.txt

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site-packages/wheel-0.33.4.dist-info/top_level.txt

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/site.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/sre.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/sre_compile.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/sre_constants.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/sre_parse.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/stat.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/types.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/envs/py2/lib/python2.7/warnings.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/libpython2.7.so

%attr(550, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/libpython2.7.so.1.0

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/pkgconfig/python-2.7.pc

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/pkgconfig/python.pc

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/pkgconfig/python2.pc

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/_LWPCookieJar.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/_MozillaCookieJar.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/__future__.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/__phello__.foo.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/_abcoll.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/_osx_support.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/_pyio.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/_strptime.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/_sysconfigdata.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/_threading_local.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/_weakrefset.py

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/lib/python2.7/some?file?with?spaces.py

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/share/man/man1/python.1

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/share/man/man1/python2.1

%attr(640, vagrant, vagrant) /home/vagrant/.pyenv/versions/2.7.16/share/man/man1/python2.7.1

%attr(777, vagrant, vagrant) /home/vagrant/.pyenv/versions/py2


%changelog

# Don't try fancy stuff like debuginfo, which is useless on binary-only
# packages. Don't strip binary too
# Be sure buildpolicy set to do nothing
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

# Allow building noarch packages that contain binaries
%define _binaries_in_noarch_packages_terminate_build 0

# Use md5 file digest method.
# The first macro is the one used in RPM v4.9.1.1
%define _binary_filedigest_algorithm 1
# This is the macro I find on OSX when Homebrew provides rpmbuild (rpm v5.4.14)
%define _build_binary_file_digest_algo 1

# Use gzip payload compression
%define _binary_payload w9.gzdio
%undefine __check_files

%define          debug_package %{nil}
%define        __os_install_post %{nil}

Summary: A very simple toy bin rpm package
Name: x
Version: 1.0
Release: 1
License: GPL+
Group: Development/Tools
URL: http://x.com/

BuildRoot: /

%description
%{summary}

%prep

%build
# Empty section.

%install
# Empty

%clean

%files
%defattr(555,vagrant,vagrant,-)
/home/vagrant/.local/bin/foo

%changelog

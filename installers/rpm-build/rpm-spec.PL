#!/usr/bin/env perl
use warnings;
use strict;
use File::Find ();

sub main {
    my($spec_name) ||= $ENV{rpm_build_base} || die;
    my($spec_description) ||= $spec_name;
    my($spec_version) = $ENV{rpm_build_version} || die;
    my($spec_summary) = (split(/\n/, $spec_description))[0];
    my($template) = (sub {local($/); return <DATA>})->();
    my($z) = {};
    foreach my $x (qw(depends include)) {
        $z->{$x} = _read_list($ENV{"rpm_build_${x}_f"} || die);
    }
    my($spec_requires) = @{$z->{depends}}
        ? join(' ', 'Requires:', @{$z->{depends}}) . "\n"
        : '';
    my($spec_files) = '';
    open(OUT, '>', $ENV{rpm_build_rsync_f}) || die("rsync.txt: $!\n");
    foreach my $f (sort(@{$z->{include}})) {
        if (-l $f || ! -d _) {
            if (! -l _ && -x _) {
                $spec_files .= '%attr(755,-,-) ';
            }
        }
        else {
            $spec_files .= '%dir ';
        }
        $spec_files .= qq{"$f"\n};
        print(OUT "$f\n");
    }
    $template =~ s/(\$spec_\w+)/$1/eeg;
    print($template);
}

sub _read_list {
    my($file) = @_;
    my($r) = Cwd::getcwd();
    open(IN, '<', $file) || die("$file: $!\n");
    chomp(my @res = <IN>);
    close(IN);
    return \@res;
}

main(@ARGV);

1;

__DATA__

# Most of this was taken from the output of fpm:

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

%define __provides_exclude_from .

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

# Avoids warning source_date_epoch_from_changelog is set, but changelog has no entries
%undefine source_date_epoch_from_changelog

# Avoids duplicate build_ids error, because pyenv copies files to virtualenv
%define _build_id_links none

%define          debug_package %{nil}
%define        __os_install_post %{nil}


# Do not generate dependencies, because they seem to get screwed up too easily,
# e.g. nothing provides libmpi.so.12()(64bit) needed by rscode-parmetis-...rpm
Autoreq: 0
Summary: $spec_summary
Name: $spec_name
Version: $spec_version
Release: 1
License: none
Group: Development/Tools
URL: none
$spec_requires

BuildRoot: %{buildroot}

%description
$spec_description

%prep
# empty

%build
# empty

%install
# empty

%clean
# empty

%files
%defattr(644,vagrant,vagrant,755)
$spec_files

%changelog

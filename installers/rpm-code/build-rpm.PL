#!/usr/bin/env perl
use warnings;
use strict;
use File::Find ();

sub main {
    my($guest_d, $spec_name, $spec_version, $spec_description) = @_;
    $spec_description ||= $spec_name;
    my($spec_summary) = (split(/\n/, $spec_description))[0];
    my($template) = (sub {local($/); return <DATA>})->();
    my($z) = {};
    foreach my $x (qw(include exclude depends)) {
        $z->{$x} = _read_list($guest_d, $x);
    }
    my($spec_requires) = @{$z->{depends}}
        ? join(' ', 'Requires:', @{$z->{depends}}) . "\n"
        : '';
    my($files) = {};
    my($dirs) = [];
    File::Find::find(
        {
            dangling_symlinks => 1,
            follow => 0,
            no_chdir => 1,
            wanted => sub {
                if (-d $File::Find::name) {
                    push(@$dirs, $File::Find::name);
                }
                else {
                    $files->{$File::Find::name} = -x _;
                }
                return;
            },
        },
        @{$z->{include}},
    );
    my($exclude) = {};
    foreach my $f (@{$z->{exclude}}) {
        while ($f !~ m{^/*$}) {
            if ($exclude->{$f}) {
                last;
            }
            $exclude->{$f} = 1;
            $f =~ s{/[^/]*$}{};
        }
    }
    my($spec_files) = '';
    my($include) = {};
    foreach my $f (sort(@$dirs)) {
        while ($f !~ m{^/*$}) {
            if ($exclude->{$f}) {
                if (grep($_ eq $f, @{$z->{include}})) {
                    $include->{$f} = 1;
                }
                last;
            }
            $include->{$f} = 1;
            $f =~ s{/[^/]*$}{};
        }
    }
    foreach my $f (sort(keys(%$include))) {
        $spec_files .= "\%dir $f\n";
    }
    foreach my $f (sort(keys(%$files))) {
        if ($files->{$f}) {
            $spec_files .= '%attr(555,-,-) ';
        }
        $spec_files .= "$f\n";
    }
    $template =~ s/(\$spec_\w+)/$1/eeg;
    print($template);
}

sub _read_list {
    my($guest_d, $base) = @_;
    my($r) = Cwd::getcwd();
    my($f) = "$guest_d/$base.txt";
    open(IN, '<', $f) || die("$f: $!\n");
    chomp(my @res = <IN>);
    close(IN);
    return \@res
        if $base eq 'depends';
    return [map(
        {
            m{^/} or die("$_: $base file must begin with '/'\n");
            s{//+}{/}g;
            # so we ensure termination on /dir1/
            s{/$}{};
            $_ or die("$_: $base file may not be '/'\n");
            $_;
        }
        @res
    )]
}

main(@ARGV);

1;
my($x) = <<'EOF';
rpm_code_build_exclude_add() {
    local d
    for d in "$@"; do
        d=$(realpath --no-symlinks --canonicalize-missing "$d")
        if [[ ! $d =~ ^/ ]]; then
            install_err "$d: must begin with a /"
        fi
        while [[ $d != / ]]; do
            if [[ ${rpm_code_build_exclude[$d]+1} ]]; then
                break
            fi
            rpm_code_build_exclude[$d]=1
            d=$(dirname "$d")
        done


    local start=$(date +%s)
    local deps=()
    local i
    for i in "${rpm_code_build_depends[@]}"; do
        echo "$i"
    done > "$rpm_code_build_depends_f"
    local -A include_dirs
    local sorted=$rpm_code_build_include_f.sorted
    sort -u "$rpm_code_build_include_f" > "$sorted"
    local d
    while IFS="" read -r i; do
        d=$i
        while true; do
            d=$(dirname "$d")
            if [[ ${rpm_code_build_exclude[$d]+1} || $d == / ]]; then
                # explicit include of a directory takes precedence
                # over exclude
                printf '%s\n' "$i"
                break
            fi
            if [[ ${include_dirs[$d]+1} ]]; then
                break
            fi
        done
        if [[ -d $i ]]; then
            include_dirs[$i]=1
        fi
    done < "$sorted" > "$rpm_code_build_include_f"
    rm -f "$sorted"
    local exclude=()
    for i in "${!rpm_code_build_exclude[@]}"; do
        if [[ ! ${include_dirs[$i]+1} ]]; then
            exclude+=( --rpm-auto-add-exclude-directories "$i" )
        fi
    done
    if [[ $install_debug ]]; then
        install_msg "$rpm_code_build_include_f"
        cat "$rpm_code_build_include_f" 1>&2
    fi
    install_info "fpm prep: $(( $(date +%s) - $start ))s"
    cd "$rpm_code_guest_d"
    FPM_EDITOR="cat > spec_file " fpm -e -t rpm -s dir -n "$rpm_base" -v "$version" \
        --rpm-rpmbuild-define "_build_id_links none" \
        --rpm-use-file-permissions --rpm-auto-add-directories \
        ${rpm_code_build_desc:+'--description' "$rpm_code_build_desc"} \
        "${exclude[@]}" \
        "${deps[@]}" \
        --inputs "$rpm_code_build_include_f" || true
    cat spec_file
EOF

__DATA__

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
%defattr(444,vagrant,vagrant,755)
$spec_files

%changelog

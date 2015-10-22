#!/bin/bash
#
# Install RadiaSoft containers
#
# TODO(robnagler):
#    - delegated argument parsing
#    - modularize better (delegation model to other repos?)
#    - add codes.sh (so can install locally and remotely)
#    - better logging for hopper install
#    - leave in directory match? (may be overkill on automation)
set -e

install_check() {
    if [[ $install_no_check ]]; then
        return
    fi
    if [[ $(ls -A | grep -v install.log) ]]; then
        install_err 'Current directory is not empty.
Please create a new directory, cd to it, and re-run this command.'
    fi
}

install_download() {
    local url=$1
    local base=$(basename "$url")
    local file=$(dirname "$0")/$base
    local res
    if [[ -r $file ]]; then
        res=$(<$file)
        install_log cat "$file"
    else
        if [[ $url == $base ]]; then
            url=$install_url/$base
        fi
        install_log curl -L -s -S "$url"
        res=$(curl -L -s -S "$url")
    fi
    if [[ ! $res =~ ^#! ]]; then
        install_err "Unable to download $url"
    fi
    echo "$res"
}

install_err() {
    install_msg "$@
If you don't know what to do, please contact support@radiasoft.net."
    exit 1
}

install_err_trap() {
    set +e
    trap - ERR
    instal_log 'Error trap'
    install_err 'Unexpected error; Install failed.'
}

install_exec() {
    install_log "$@"
    if [[ $install_verbose ]]; then
        "$@" 2>&1 | tee -a $install_log_file
    else
        "$@" >> $install_log_file 2>&1
    fi
}

install_info() {
    local f=install_msg
    if [[ $install_verbose ]]; then
        install_log "$@" ...
    fi
    #TODO(robnagler) $install_silent
    $f "$@" ...
}

install_log() {
    echo "$(date -u '+%m/%d/%Y %H:%M:%S')" "$@" >> $install_log_file
    if [[ $install_verbose ]]; then
        install_msg "$@"
    fi
}

install_main() {
    install_log_file=$PWD/install.log
    trap install_err_trap ERR
    install_log install_main
    install_vars "$@"
    install_check
    eval "$(install_download $install_type.sh)"
}

install_msg() {
    echo "$@" 1>&2
}

install_usage() {
    install_err "$@
usage: $(basename $0) [docker|hopper|vagrant] beamsim|python2|sirepo|synergia"
}

install_vars() {
    if [[ hopper == $NERSC_HOST ]]; then
        install_type=hopper
    else
        case "$(uname)" in
            [Dd]arwin)
                if [[ $(type -t vagrant) ]]; then
                    install_type=vagrant
                else
                    install_err 'Please install Vagrant and restart install'
                fi
                ;;
            [Ll]inux)
                if [[ $(type -t docker) ]]; then
                    install_type=docker
                elif [[ $(type -t vagrant) ]]; then
                    install_type=vagrant
                else
                    install_err 'Please install Docker or Vagrant and restart install'
                fi
                ;;
            *)
                install_err "$(uname) is an unsupported system, sorry"
                ;;
        esac
    fi
    install_image=
    install_forward_port=
    install_verbose=
    while [[ "$1" ]]; do
        case "$1" in
            beamsim|python2|sirepo)
                install_image=$1
                ;;
            hopper)
                install_type=$1
                ;;
            synergia)
                install_image=$1
                ;;
            vagrant|docker)
                install_type=$1
                ;;
            verbose)
                install_verbose=1
                ;;
            quiet)
                install_verbose=
                ;;
            *)
                install_usage "$1: unknown install option"
                ;;
        esac
        shift
    done
    if [[ ! $install_image ]]; then
        install_image=$(basename "$PWD")
        if [[ ! $install_image =~ ^(beamsim|python2|sirepo)$ ]]; then
            install_usage "Please supply a install name: beamsim, python2, sirepo, synergia"
        fi
    fi
    if [[ $install_image =~ sirepo ]]; then
        install_forward_port=8000
    fi
    case $install_type in
        vagrant|docker)
            if [[ $NERSC_HOST ]]; then
                install_usage "You can't install vagrant or docker at NERSC"
            fi
            if [[ $install_image == synergia ]]; then
                install_msg 'Switching image to "beamsim" which includes synergia'
                install_image=beamsim
            fi
            install_image=radiasoft/$install_image
            ;;
        hopper)
            install_no_check=1
            if [[ $NERSC_HOST != hopper ]]; then
                install_usage "You are not running on $install_type so can't install"
            fi
            if [[ $install_image != synergia ]]; then
                install_usage "Can only install synergia on $install_type"
            fi
            ;;
    esac
    install_url=https://raw.githubusercontent.com/radiasoft/download/master/bin
}

install_main "$@"

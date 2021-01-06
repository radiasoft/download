#!/bin/bash

vagrant_perl_dev_main() {
    vagrant_dev_post_install_repo=perl-dev install_repo_eval vagrant-dev centos/7 "$@"
    install_repo_eval vagrant-dev centos/7 "$@"
}

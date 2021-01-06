#!/bin/bash

vagrant_sirepo_dev_main() {
    vagrant_dev_post_install_repo=sirepo-dev install_repo_eval vagrant-dev fedora "$@"
}

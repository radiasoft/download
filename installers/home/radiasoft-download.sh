#!/bin/bash
#
# To run: curl radia.run | bash -s home
#
home_main() {
    install_url biviosoftware/home-env
    bivio_home_env_ignore_git_dir_ownership=${vagrant_dev_ignore_git_dir_ownership:+1}  \
        install_script_eval install.sh
}

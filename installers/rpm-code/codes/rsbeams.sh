#!/bin/bash

rsbeams_main() {
    codes_dependencies common
    rsbeams_pwd=$PWD
    rsbeams_python_versions=3
    for r in rsbeams rssynergia rsoopic rswarp; do
        codes_download radiasoft/"$r"
        cd ..
    done

}

rsbeams_python_install() {
    for r in rsbeams rssynergia rsoopic rswarp; do
        cd "$r"
        codes_python_install
        cd ..
    done
}

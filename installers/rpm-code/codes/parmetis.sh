#!/bin/bash


parmetis_main() {
    codes_dependencies common
    for f in GKlib METIS ParMETIS; do
        codes_download KarypisLab/"$f"
        make config prefix="${codes_dir[prefix]}"
        codes_make_install
        cd ..
    done
}

#!/bin/bash


parmetis_main() {
    echo "${codes_dir[prefix]}"
    codes_dependencies common
    for f in GKlib METIS ParMETIS; do
        codes_download KarypisLab/"$f"
        codes_cmake_fix_lib_dir
        # gklib_path is hardwired incorrectly in Makefile
        make config prefix="${codes_dir[prefix]}" gklib_path="${codes_dir[prefix]}"
        codes_make_install
        cd ..
    done
}

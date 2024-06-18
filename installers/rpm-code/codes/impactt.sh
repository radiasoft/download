#!/bin/bash

impactt_main() {
    # openpmdapi provides openpmd-beamphysics which is required by lume-base
    # pydicom is required by one of lume-base deps
    codes_dependencies common openpmdapi pydicom
    codes_download https://github.com/impact-lbl/impact-t.git
    cd src
    codes_cmake2 -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_cmake_build install
    codes_cmake_clean
    codes_cmake2 -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" -DUSE_MPI=ON
    codes_cmake_build install
    codes_cmake_clean
}

impactt_python_install() {
    # Requirements for lume-impact aren't installed in a pip install.
    # https://github.com/ChristopherMayes/lume-impact/blob/5593a87d722a91d3d66df2804731a281fddd3aa1/pyproject.toml#L20
    codes_download https://github.com/ColwynGulliford/distgen.git v2.0.2
    codes_python_install
    install_pip_install lume-base==0.3.2
    codes_download https://github.com/ChristopherMayes/lume-impact.git 5593a87d722a91d3d66df2804731a281fddd3aa1
    codes_python_install
}

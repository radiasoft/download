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
    # https://github.com/ChristopherMayes/lume-impact/blob/master/pyproject.toml#L14
    codes_download https://github.com/ColwynGulliford/distgen.git v2.1.6
    codes_python_install
    install_pip_install polars-lts-cpu
    install_pip_install pydantic_settings
    install_pip_install prettytable
    install_pip_install eval_type_backport
    install_pip_install lume-base==0.3.3
    codes_download https://github.com/ChristopherMayes/lume-impact.git v0.10.2
    codes_python_install
}

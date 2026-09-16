#!/bin/bash

impactt_main() {
    # openpmdapi provides openpmd-beamphysics which is required by lume-base
    # pydicom is required by one of lume-base deps
    codes_dependencies common openpmdapi pydicom
    codes_download https://github.com/impact-lbl/impact-t.git v3.1.5
    cd src
    codes_cmake2
    codes_cmake_build install
    codes_cmake_clean
    codes_cmake2 -DUSE_MPI=ON
    codes_cmake_build install
    codes_cmake_clean
}

impactt_python_install() {
    codes_download https://github.com/ColwynGulliford/distgen.git v2.3.1
    codes_python_install
    codes_download https://github.com/lume-science/lume-impact.git v0.12.1
    codes_python_install
    # lume-impact pulls in polars + polars-runtime-32 (the split-runtime
    # packaging), which we don't want, because it requires a newer CPU;
    # replace it with the CPU-compatible variant
    pip uninstall -y polars polars-runtime-32
    install_pip_install --force-reinstall --no-deps polars-lts-cpu==1.33.1
}

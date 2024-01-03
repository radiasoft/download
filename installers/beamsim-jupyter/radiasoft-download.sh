#!/bin/bash
#
# Install dependencies common to beamsim-jupyter and container-jupyter-nvidia but
# install the correct version for gpu vs not.
#

beamsim_jupyter_main() {
    declare want_gpu=${1:-}
    beamsim_jupyter_common
    if [[ $want_gpu ]]; then
        beamsim_jupyter_want_gpu
    else
        beamsim_jupyter_no_gpu
    fi
}

beamsim_jupyter_common() {
    llvmlite
    numba

    # needs to be before fbpic https://github.com/radiasoft/devops/issues/153
    pyfftw
    # https://github.com/radiasoft/devops/issues/152
    fbpic

# temporarily disable https://github.com/radiasoft/container-beamsim-jupyter/issues/40
#        # https://github.com/radiasoft/jupyter.radiasoft.org/issues/75
#        gpflow
    # https://github.com/radiasoft/container-beamsim-jupyter/issues/10
    GPy
    # https://github.com/radiasoft/container-beamsim-jupyter/issues/11
    safeopt
    # https://github.com/radiasoft/container-beamsim-jupyter/issues/13
    seaborn
    # https://github.com/radiasoft/container-beamsim-jupyter/issues/38
    # https://github.com/radiasoft/container-beamsim-jupyter/issues/39
    botorch
    # needed by zgoubidoo
    parse

    # https://github.com/radiasoft/container-beamsim-jupyter/issues/32
    # installs bokeh, too
    git+https://github.com/slaclab/lume-genesis
    git+https://github.com/ChristopherMayes/openPMD-beamphysics
    git+https://github.com/radiasoft/zfel

    # https://github.com/radiasoft/container-beamsim-jupyter/issues/42
    bluesky
}

# We need to pin versions because package versions need to be kept in
# sync with gpu software versions (cuda).
beamsim_jupyter_want_gpu() {
    install_pip_install --index-url https://download.pytorch.org/whl/cu121 \
        torch==2.1.2 \
        torchaudio==2.1.2 \
        torchvision==0.16.2
    pip uninstall -y tensorflow
    install_pip_install tensorflow[and-cuda]==2.15.0
}

# Match gpu versions to make it easy to move between environments.
beamsim_jupyter_no_gpu() {
    install_pip_install --index-url https://download.pytorch.org/whl/cpu \
        torch==2.1.2 \
        torchaudio==2.1.2 \
        torchvision==0.16.2
}

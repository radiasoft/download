#!/bin/bash
#
# ML dependencies. GPU, CPU, and common (installed on GPU and CPU).
#

_ml_python_tensorflow_version=2.20.0

# Need to peg for torch-scatter and sparse wheels,
# otherwise it builds these packages which take forever.
# They were both last updated in 2023.
_ml_python_torch_version=2.8.0
_ml_python_torch_base=(
    torchaudio==$_ml_python_torch_version
    torchvision~=0.23.0
    torch==$_ml_python_torch_version
)
_ml_python_torch_extras=(
    torch-scatter~=2.1.2
    torch-sparse~=0.6.18
)

ml_python_common() {
    declare p=(
        h5ImageGenerator
    )
    install_pip_install "${p[@]}"
}

# Match gpu versions to make it easy to move between environments.
ml_python_cpu() {
    install_pip_install tensorflow-cpu~="$_ml_python_tensorflow_version"
    # index-url finds the right wheel
    install_pip_install --index-url=https://download.pytorch.org/whl/cpu "${_ml_python_torch_base[@]}"
    # find-links the right wheel for cluster, scatter, sparse, and spline, and pyg_lib
    install_pip_install \
        --find-links="https://data.pyg.org/whl/torch-$_ml_python_torch_version%2Bcpu.html" \
        "${_ml_python_torch_extras[@]}"
}

ml_python_main() {
    declare mode=$1
    ml_python_common
    case $mode in
        gpu)
            ml_python_gpu
            ;;
        cpu)
            ml_python_cpu
            ;;
        *)
            install_err "unknown mode=$mode"
            ;;
    esac
}

# We need to pin versions because package versions need to be kept in
# sync with gpu software versions (cuda).
ml_python_gpu() {
    install_err broken versions see cpu
    install_pip_install --index-url https://download.pytorch.org/whl/cu121 \
        "${_ml_python_torch_base[@]}"
    install_pip_install --find-links https://data.pyg.org/whl/torch-2.1.0+cu121.html \
        "${_ml_python_torch_extras[@]}"
    # Tensorflow, python, cuda, compatability matrix
    # https://www.tensorflow.org/install/source#gpu
    install_pip_install tensorflow[and-cuda]~="$_ml_python_tensorflow_version"
}

#!/bin/bash
#
# ML dependencies. GPU, CPU, and common (installed on GPU and CPU).
#

_ml_python_tensorflow_version=2.15.0
_ml_python_torch_base=(
    torchaudio~=2.1.0
    torchvision~=0.16.0
    torch~=2.1.0
)
_ml_python_torch_extras=(
    torch-scatter~=2.1.0
    torch-sparse~=0.6.0
)

ml_python_common() {
    declare p=(
        h5ImageGenerator
        scikit-learn
        sympy
    )
    install_pip_install "${p[@]}"
}

# Match gpu versions to make it easy to move between environments.
ml_python_cpu() {
    install_pip_install tensorflow~="$_ml_python_tensorflow_version"
    install_pip_install --index-url https://download.pytorch.org/whl/cpu \
        "${_ml_python_torch_base[@]}"
    install_pip_install --find-links https://data.pyg.org/whl/torch-2.1.0+cpu.html \
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
    install_pip_install --index-url https://download.pytorch.org/whl/cu121 \
        "${_ml_python_torch_base[@]}"
    install_pip_install --find-links https://data.pyg.org/whl/torch-2.1.0+cu121.html \
        "${_ml_python_torch_extras[@]}"
    # Tensorflow, python, cuda, compatability matrix
    # https://www.tensorflow.org/install/source#gpu
    install_pip_install tensorflow[and-cuda]~="$_ml_python_tensorflow_version"
}

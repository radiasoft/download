#!/bin/bash

ml_main() {
    codes_yum_dependencies graphviz
    codes_dependencies common pydot
}

ml_python_install() {
    install_pip_install h5ImageGenerator
    # The tensorflow version we install must be supported by the CUDA version we have installed
    # https://www.tensorflow.org/install/source#gpu
    # deps copied from tensorflow/tools/pip_package/setup.py
    local x=(
    'absl-py>=1.0.0'
    'astunparse>=1.6.0'
    'flatbuffers>=23.5.26'
    'gast>=0.2.1,!=0.5.0,!=0.5.1,!=0.5.2'
    'google_pasta>=0.1.1'
    'h5py>=2.9.0'
    'libclang>=13.0.0'
    'ml_dtypes~=0.2.0'
    'numpy>=1.23.5,<2.0.0'
    'opt_einsum>=2.3.2'
    'packaging'
    'protobuf>=3.20.3,<5.0.0dev,!=4.21.0,!=4.21.1,!=4.21.2,!=4.21.3,!=4.21.4,!=4.21.5'
    'setuptools'
    'six>=1.12.0'
    'termcolor>=1.1.0'
    'typing_extensions>=3.6.6'
    'wrapt>=1.11.0,<1.15'
    'tensorflow-io-gcs-filesystem>=0.23.1'
    'grpcio>=1.24.3,<2.0' # sys.byteorder == 'little' on our systems
    'tensorboard>=2.15,<2.16'
    'tensorflow_estimator>=2.15.0,<2.16'
    'keras>=2.15.0,<2.16'
    )
    install_pip_install "${x[@]}"
    install_pip_install --no-deps tensorflow==2.15.0
    # scikit is need for srw
    # sympy is needed for webcon and rsbeams
    install_pip_install scikit-learn sympy
}

#!/bin/bash

ml_main() {
    codes_yum_dependencies graphviz
    codes_dependencies common pydot
}

ml_python_install() {
    install_pip_install h5ImageGenerator
    if install_version_fedora_is_36; then
        ml_python_install_f36
        return
    fi
    ml_python_install_f32
}

ml_python_install_f32() {
    declare x=(
        'absl-py>=0.7.0'
        'gast==0.3.3'
        'google-pasta>=0.1.8'
        'grpcio>=1.8.6'
        'keras-preprocessing<1.2,>=1.1.1'
        'opt-einsum>=2.3.2'
        'protobuf>=3.9.2'
        'tensorboard<3,>=2.3.0'
        'google-auth<2,>=1.6.3'
        'cachetools<5.0,>=2.0.0'
        'google-auth-oauthlib<0.5,>=0.4.1'
        'markdown>=2.6.8'
        'pyasn1-modules>=0.2.1'
        'pyasn1<0.5.0,>=0.4.6'
        'requests-oauthlib>=0.7.0'
        'oauthlib>=3.0.0'
        'rsa<5,>=3.1.4'
        'tensorboard-plugin-wit>=1.6.0'
        'tensorflow-estimator<2.4.0,>=2.3.0'
        'termcolor>=1.1.0'
        'werkzeug>=0.11.15'
    )
    install_pip_install "${x[@]}"
    install_pip_install --no-deps tensorflow==2.3.1
    install_pip_install keras==2.4.3 \
        scikit-learn

}


ml_python_install_f36() {
    # sympy is needed for webcon and rsbeams
    # scikit-image is need for srw

    # deps copied from tensorflow/tools/pip_package/setup.py
    local x=(
        'absl-py>=1.0.0'
        'astunparse>=1.6.0'
        'flatbuffers>=2.0'
        'gast>=0.2.1,<=0.4.0'
        'google_pasta>=0.1.1'
        'grpcio>=1.24.3,<2.0' # sys.byteorder == 'little' on our systems
        'h5py>=2.9.0'
        'keras>=2.10.0,<2.11'
        'keras_preprocessing>=1.1.1'
        'libclang>=13.0.0'
        'numpy>=1.20'
        'opt_einsum>=2.3.2'
        'packaging'
        'protobuf>=3.9.2,<3.20'
        'setuptools'
        'six>=1.12.0'
        'tensorboard>=2.10,<2.11'
        'tensorflow-io-gcs-filesystem>=0.23.1'
        'tensorflow_estimator>=2.10.0,<2.11'
        'termcolor>=1.1.0'
        'typing_extensions>=3.6.6'
        'wrapt>=1.11.0'
    )
    install_pip_install "${x[@]}"
    install_pip_install --no-deps tensorflow==2.10.0
    install_pip_install scikit-learn

}

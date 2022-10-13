#!/bin/bash

ml_main() {
    codes_yum_dependencies graphviz
    codes_dependencies common pydot
}

ml_python_install() {
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
        'keras_preprocessing>=1.1.1'
        'libclang>=13.0.0'
        'numpy>=1.20'
        'opt_einsum>=2.3.2'
        'packaging'
        'protobuf>=3.9.2,<3.20'
        'setuptools'
        'six>=1.12.0'
        'tensorflow-io-gcs-filesystem>=0.23.1'
        'termcolor>=1.1.0'
        'typing_extensions>=3.6.6'
        'wrapt>=1.11.0'
    )
    install_pip_install "${x[@]}"
    install_pip_install --no-deps tensorflow==2.10.0
    install_pip_install scikit-learn
}


# install_pip_install tensorflow
# Collecting tensorflow
#   Downloading tensorflow-2.3.1-cp37-cp37m-manylinux2010_x86_64.whl (320.4 MB)
# Collecting absl-py>=0.7.0
#   Downloading absl_py-0.11.0-py3-none-any.whl (127 kB)
# Collecting astunparse==1.6.3
#   Downloading astunparse-1.6.3-py2.py3-none-any.whl (12 kB)
# Collecting gast==0.3.3
#   Downloading gast-0.3.3-py2.py3-none-any.whl (9.7 kB)
# Collecting google-pasta>=0.1.8
#   Downloading google_pasta-0.2.0-py3-none-any.whl (57 kB)
# Collecting grpcio>=1.8.6
#   Downloading grpcio-1.34.0-cp37-cp37m-manylinux2014_x86_64.whl (3.9 MB)
# Collecting keras-preprocessing<1.2,>=1.1.1
#   Downloading Keras_Preprocessing-1.1.2-py2.py3-none-any.whl (42 kB)
# Collecting opt-einsum>=2.3.2
#   Downloading opt_einsum-3.3.0-py3-none-any.whl (65 kB)
# Collecting protobuf>=3.9.2
#   Downloading protobuf-3.14.0-cp37-cp37m-manylinux1_x86_64.whl (1.0 MB)
# Collecting tensorboard<3,>=2.3.0
#   Downloading tensorboard-2.4.0-py3-none-any.whl (10.6 MB)
# Collecting google-auth<2,>=1.6.3
#   Downloading google_auth-1.24.0-py2.py3-none-any.whl (114 kB)
# Collecting cachetools<5.0,>=2.0.0
#   Downloading cachetools-4.2.0-py3-none-any.whl (12 kB)
# Collecting google-auth-oauthlib<0.5,>=0.4.1
#   Downloading google_auth_oauthlib-0.4.2-py2.py3-none-any.whl (18 kB)
# Collecting markdown>=2.6.8
#   Downloading Markdown-3.3.3-py3-none-any.whl (96 kB)
# Collecting pyasn1-modules>=0.2.1
#   Downloading pyasn1_modules-0.2.8-py2.py3-none-any.whl (155 kB)
# Collecting pyasn1<0.5.0,>=0.4.6
#   Downloading pyasn1-0.4.8-py2.py3-none-any.whl (77 kB)
# Collecting requests-oauthlib>=0.7.0
#   Downloading requests_oauthlib-1.3.0-py2.py3-none-any.whl (23 kB)
# Collecting oauthlib>=3.0.0
#   Downloading oauthlib-3.1.0-py2.py3-none-any.whl (147 kB)
# Collecting rsa<5,>=3.1.4
#   Downloading rsa-4.6-py3-none-any.whl (47 kB)
# Collecting tensorboard-plugin-wit>=1.6.0
#   Downloading tensorboard_plugin_wit-1.7.0-py3-none-any.whl (779 kB)
# Collecting tensorflow-estimator<2.4.0,>=2.3.0
#   Downloading tensorflow_estimator-2.3.0-py2.py3-none-any.whl (459 kB)
# Collecting termcolor>=1.1.0
#   Downloading termcolor-1.1.0.tar.gz (3.9 kB)
# Collecting werkzeug>=0.11.15
#   Downloading Werkzeug-1.0.1-py2.py3-none-any.whl (298 kB)
# Collecting wrapt>=1.11.1
#   Downloading wrapt-1.12.1.tar.gz (27 kB)
# Building wheels for collected packages: termcolor, wrapt
#   Building wheel for termcolor (setup.py) ... [?25ldone
#   Created wheel for termcolor: filename=termcolor-1.1.0-py3-none-any.whl size=4832 sha256=dbda56b58da20598fc3fdd0107002fc11654dd206a7ee73dbbd0d574075b8dd5
#   Stored in directory: /home/vagrant/.cache/pip/wheels/3f/e3/ec/8a8336ff196023622fbcb36de0c5a5c218cbb24111d1d4c7f2
#   Building wheel for wrapt (setup.py) ... [?25ldone
#   Created wheel for wrapt: filename=wrapt-1.12.1-cp37-cp37m-linux_x86_64.whl size=71804 sha256=bf18b2ce2c3a980c73a7012bb3598f6a60e2126925b128ece7341eeba98853bd
#   Stored in directory: /home/vagrant/.cache/pip/wheels/62/76/4c/aa25851149f3f6d9785f6c869387ad82b3fd37582fa8147ac6
# Successfully built termcolor wrapt
# Installing collected packages: pyasn1, rsa, pyasn1-modules, oauthlib, cachetools, requests-oauthlib, google-auth, werkzeug, tensorboard-plugin-wit, protobuf, markdown, grpcio, google-auth-oauthlib, absl-py, wrapt, termcolor, tensorflow-estimator, tensorboard, opt-einsum, keras-preprocessing, google-pasta, gast, astunparse, tensorflow
# Successfully installed absl-py-0.11.0 astunparse-1.6.3 cachetools-4.2.0 gast-0.3.3 google-auth-1.24.0 google-auth-oauthlib-0.4.2 google-pasta-0.2.0 grpcio-1.34.0 keras-preprocessing-1.1.2 markdown-3.3.3 oauthlib-3.1.0 opt-einsum-3.3.0 protobuf-3.14.0 pyasn1-0.4.8 pyasn1-modules-0.2.8 requests-oauthlib-1.3.0 rsa-4.6 tensorboard-2.4.0 tensorboard-plugin-wit-1.7.0 tensorflow-2.3.1 tensorflow-estimator-2.3.0 termcolor-1.1.0 werkzeug-1.0.1 wrapt-1.12.1

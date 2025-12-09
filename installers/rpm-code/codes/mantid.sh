#!/bin/bash

mantid_main() {
    # These were determined by running cmake for the various packages and seeing what
    # was missing.
    # There is also the mantid-developer package that is a meta package of all of the dependencies.
    # https://developer.mantidproject.org/GettingStarted.html#red-hat-cent-os-fedora
    # https://copr.fedorainfracloud.org/coprs/mantid/mantid/packages/
    codes_yum_dependencies \
        eigen3-devel \
        jemalloc-devel \
        jsoncpp-devel \
        muParser-devel \
        poco-devel \
        tbb-devel
    codes_dependencies common boost ipykernel
    install_pip_install pre-commit pylint sphinx_bootstrap_theme
    mantid_nexus_install
    # Mantid installs a great deal and requires its own specific environment variables to run right
    # (ex. see the mantidpython script it creates). So, install it in its own subdirectory so it
    # doesn't interfere with other libs.
    local p="${codes_dir[lib]}/mantid"
    mantid_install "$p"
    mantid_ipykernel "$p" "$(mantid_install_rsmantid "$p")"
}

mantid_install() {
    local install_prefix=$1
    codes_download mantidproject/mantid v6.4.0
    codes_cmake2 \
        -DBOOST_ROOT="${codes_dir[prefix]}" \
        -DENABLE_DOCS=OFF \
        -DENABLE_MANTIDQT=OFF \
        -DENABLE_OPENCASCADE=OFF \
        -DENABLE_OPENGL=OFF \
        -DENABLE_WORKBENCH=OFF \
        -DMANTID_FRAMEWORK_LIB=BUILD \
        -DMANTID_QT_LIB=OFF \
        -DNEXUS_CPP_LIBRARIES="${codes_dir[lib]}"/libNeXusCPP.so \
        -DNEXUS_C_LIBRARIES="${codes_dir[lib]}"/libNeXus.so \
        -DNEXUS_INCLUDE_DIR="${codes_dir[include]}"/nexus/ \
        '-GUnix Makefiles'
    codes_cmake_build install
}

mantid_install_rsmantid() {
    local install_d=$1
    local s=rsmantid
    codes_download_module_file "$s.sh"
    local l=$install_d/bin/mantidpython
    install -m 555 /dev/stdin "${codes_dir[bin]}/$s" <<EOF
#!/bin/bash
set -euo pipefail
exec '$l' --classic "\$@"
EOF
    echo "$l"
}

mantid_ipykernel() {
    local INSTALLDIR=$1
    local mantidpython=$2
    local LOCAL_PRELOAD LOCAL_PYTHONPATH LOCAL_LDPATH
    eval "$(grep -P '^LOCAL_\w+=' "$mantidpython")"
    python -m ipykernel install \
        --display-name 'Mantid Python' \
        --name pymantid \
        --user \
        --env PYTHONPATH "$LOCAL_PYTHONPATH" \
        --env LD_PRELOAD "$LOCAL_PRELOAD"
    # LOCAL_LDPATH is empty in the current install so we don't include it.
    # To be correct, we would need to know the value at runtime (not buildtime)
    # of LD_LIBRARY_PATH in order to prefix LOCAL_LDPATH. This is problematic,
    # and ipykernel doesn't allow us do this dynamically (it doesn't know).
    # The same is true of the other vars, but we know they are empty by default.
}

mantid_nexus_install() {
    codes_download nexusformat/code
    codes_cmake -DENABLE_HDF5=1 -DENABLE_CXX=1 -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make
    codes_make_install
    cd ../
}

mantid_test() {
    rsmantid <<EOF
import mantid.simpleapi
import time

# mantid import starts a process which downloads support files
# it needs to complete before the program exits otherwise it segfaults.
# Sleep to give it time.
time.sleep(10)
EOF
}

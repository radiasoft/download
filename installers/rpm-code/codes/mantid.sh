#!/bin/bash

mantid_main() {
    codes_yum_dependencies \
        eigen3-devel \
        OCE-devel \
        jemalloc-devel \
        jsoncpp-devel \
        muParser-devel \
        poco-devel
    codes_dependencies common boost ipykernel
    install_pip_install pre-commit pylint sphinx_bootstrap_theme
    mantid_nexus_install
    # Mantid installs a great deal and requires its own specific environment variables to run right
    # (ex. see the mantidpython script it creates). So, install it in its own subdirectory so it
    # doesn't interfere with other libs.
    local p="${codes_dir[lib]}/mantid"
    mantid_install "$p"
    mantid_ipykernel $(mantid_install_rsmantid "$p")
}

mantid_install() {
    local install_prefix="$1"
    codes_download mantidproject/mantid
    mantid_patch_eigen_cmake
    codes_cmake \
        -DBOOST_ROOT="${codes_dir[prefix]}" \
        -DCMAKE_INSTALL_PREFIX="$install_prefix" \
        -DENABLE_WORKBENCH=OFF \
        -DMANTID_FRAMEWORK_LIB=BUILD \
        -DMANTID_QT_LIB=OFF \
        -DNEXUS_CPP_LIBRARIES="${codes_dir[lib]}"/libNeXusCPP.so \
        -DNEXUS_C_LIBRARIES="${codes_dir[lib]}"/libNeXus.so \
        -DNEXUS_INCLUDE_DIR="${codes_dir[include]}"/nexus/ \
        -G'Unix Makefiles'
    codes_cmake_build
    codes_make_install
}

mantid_install_rsmantid() {
    local install_d="$1"
    local s=rsmantid
    codes_download_module_file "$s.sh"
    local l="$install_d/bin/mantidpython"
    MANTID_PYTHON_SCRIPT_INSTALL_LOCATION="$l" \
        perl -p -e 's/\$\{(\w+)\}/$ENV{$1} || die("$1: not found")/eg' "$s.sh" \
        | install -m 555 /dev/stdin "${codes_dir[bin]}"/"$s"
    echo "$l"
}

mantid_ipykernel() {
    # Needs to be in same dir as $1 because script uses relative paths
    local p="$1-$RANDOM"
    patch --quiet --output="$p" "$1" <<'EOF'
@@ -54,5 +54,5 @@
 fi

-LD_PRELOAD=${LOCAL_PRELOAD} \
+echo LD_PRELOAD=${LOCAL_PRELOAD} \
     PYTHONPATH=${LOCAL_PYTHONPATH} \
     QT_API=${LOCAL_QT_API} \
EOF
    local -a e=( $(bash "$p"))
    e=( "${e[@]::${#e[@]}-5}" )
    local -a r=()
    local v
    for v in  ${e[@]::${#e[@]}-5}; do
        IFS='=' read -ra x <<< "$v"
        r+=" --env ${x[0]} ${x[1]}"
    done

    python -m ipykernel install \
        --display-name "Mantid Python" \
        --name "pymantid" \
        --user \
        --env PYENV_VERSION py3 \
        ${r[@]}
    rm "$p"
}

mantid_nexus_install() {
    codes_download nexusformat/code
    codes_cmake_fix_lib_dir
    codes_cmake -DENABLE_HDF5=1 -DENABLE_CXX=1 -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}"
    codes_make
    codes_make_install
    cd ../
}

mantid_patch_eigen_cmake() {
    # TODO(e-carlin): f32 eigen3 is 3.3.  Mantid technically depends on Eigen3 3.4 but the change
    # that bumped 3.3 to 3.4 (6d5aa8a43d980d2ea0cf919da64fd3a2c44def0d) made no other other changes
    # to the code. So, use 3.3 for now and see if there are any issues.
    echo 'find_package(Eigen3 3.3 REQUIRED)' > ./buildconfig/CMake/Eigen.cmake
}

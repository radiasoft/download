#!/bin/bash

_elegant_arch=linux-x86_64

elegant_build() {
    declare h=$PWD
    export PATH=$h/epics/base/bin/linux-x86_64:$h/epics/extensions/bin/linux-x86_64:$h/oag/apps/bin/linux-x86_64:$PATH
    export HOST_ARCH=linux-x86_64
    export EPICS_HOST_ARCH=linux-x86_64
    export RPN_DEFNS=$h/.defns.rpn
    mkdir epics
    cd epics
    elegant_curl https://epics.anl.gov/download/base/base-7.0.9.tar.gz
    ln -s base-7.0.9 base
    install_git_clone https://github.com/epics-extensions/extensions
    cd ..
    elegant_curl https://ops.aps.anl.gov/downloads/SDDS.5.9.tar.gz
    elegant_curl https://ops.aps.anl.gov/downloads/oag.apps.configure.tar.gz
    elegant_curl https://ops.aps.anl.gov/downloads/oag.1.29.tar.gz
    elegant_curl https://ops.aps.anl.gov/downloads/elegant.2025.3.0.tar.gz
    cd epics/base/configure
    echo "SHARED_LIBRARIES=NO" >> CONFIG
    echo "LINKER_USE_RPATH=NO" >> CONFIG
    echo "COMMANDLINE_LIBRARY=" >> CONFIG
    echo "USR_CFLAGS+=-std=gnu11"  >> CONFIG
    echo "USR_INCLUDES+=-I${codes_dir[include]}"  >> CONFIG
    cd ..
    make -j$(codes_num_cores)
    cd ../extensions/configure
    make clean all
    cd ../src/SDDS
    make clean
    make -j$(codes_num_cores)
    make -j$(codes_num_cores)
    make
    cd ../../../..
    cd oag/apps/configure
    echo "EPICS_BASE=$(dirname $(dirname $(dirname $(pwd))))/epics/base" >> RELEASE
    echo "EPICS_EXTENSIONS=$(dirname $(dirname $(dirname $(pwd))))/epics/extensions" >> RELEASE
    cd ../src/elegant
    make clean
    make -j$(codes_num_cores)
    cd ../../../..
}

elegant_curl() {
    declare uri=$1
    codes_curl "$uri" | tar xzf -
}

elegant_install_bin() {
    # Not installing things like:
    # ./oag/apps/src/physics/spectraCLITemplates
    # ./oag/apps/src/elegant/ringAnalysisTemplates
    # ./oag/apps/src/elegant/elegantTools/*.lte
    #
    # Some epics/extensions/src/SDDS/SDDSaps are not in the sdds or elegant rpm
    # but we install them anyway (e.g. sdds2stl, col2sdds) since they don't collide
    declare f b
    declare dst=${codes_dir[bin]}
    if [[ ${1:-}  == 'gpu-only' ]]; then
	# Make creates an executable for gpu based elegant named
	# elegant. This name conflicts with the executable for running
	# elegant on a single core. So, rename to gpu-elegant.
	install -m 555 "oag/apps/bin/$_elegant_arch/elegant" "$dst/gpu-elegant"
	return
    fi
    # Exclude a few not too generally named apps. Elegant installs a
    # lot of files but it's too hard to know what is used and
    # isn't. These have never been installed by us.
    declare exclude=' mecho minpath tmpname tcomp token timeconvert '
    for f in {oag/apps,epics/extensions}/bin/"$_elegant_arch"/*; do
        install -m 555 "$f" "$dst"
        if [[ ! $exclude =~ " $(basename "$f") " ]]; then
            install -m 555 "$f" "$dst"
        fi
    done
}

elegant_install_share() {
    declare share_d=${codes_dir[share]}/elegant
    install -d -m 755 "$share_d"
    install -m 444 oag/apps/src/elegant/LICENSE "$share_d"
    codes_curl https://ops.aps.anl.gov/downloads/defns.rpn | install -m 444 /dev/stdin "$share_d/defns.rpn"
    install -m 444 /dev/stdin "${codes_dir[bashrc_d]}/rscode-elegant.sh" <<EOF
#!/bin/bash
export RPN_DEFNS=$share_d/defns.rpn
EOF
}

elegant_main() {
    codes_yum_dependencies subversion
    codes_dependencies common boost
    elegant_build
    elegant_install_bin
    elegant_install_share
}

elegant_python_install() {
    install_pip_install sdds
}

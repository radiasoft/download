#!/bin/bash

aravis_main() {
    # Not visible in GH tabs: https://github.com/AravisProject/aravis/releases
    codes_yum_dependencies \
        cmake \
        g++ \
        gettext \
        glib2-devel \
        gobject-introspection \
        gobject-introspection-devel \
        gstreamer1-devel \
        gstreamer1-plugins-base-devel \
        gstreamer1-plugins-good \
        gtk-doc \
        gtk3-devel \
        libusb1-devel \
        libxml2-devel \
        libxslt \
        meson \
        python-gobject
    codes_dependencies common
    codes_download https://github.com/AravisProject/aravis/releases/download/0.8.31/aravis-0.8.31.tar.xz
    meson setup \
        --prefix="${codes_dir[prefix]}" \
        --libdir="${codes_dir[prefix]}"/lib build
    cd build
    ninja -j"$(codes_num_cores)"
    ninja install
}

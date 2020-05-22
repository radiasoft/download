#!/bin/bash

madx_main() {
    codes_dependencies common
    codes_download https://github.com/MethodicalAcceleratorDesign/MAD-X/archive/5.05.01.tar.gz MAD-X-5.05.01 madx 5.05.01
    codes_cmake
    codes_make
    install -m 755 build/madx64  "${codes_dir[bin]}"/madx
}

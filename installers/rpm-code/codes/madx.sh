#!/bin/bash

madx_main() {
    codes_dependencies common
    local v=5.07.00
    codes_download https://github.com/MethodicalAcceleratorDesign/MAD-X/archive/$v.tar.gz MAD-X-$v madx $v
    perl -pi -e '
        s{.3-9...0-9...0-9.}{[0-9]+\\\\.[0-9]+\\\\.+[0-9]};
        s{(?=\-funroll-loops)}{-fallow-invalid-boz };
    ' cmake/compilers/setupGNU.cmake
    perl -pi -e 's{(?=^time_t)}{extern }' src/mad_gvar.h
    codes_cmake
    codes_make
    install -m 755 src/madx  "${codes_dir[bin]}"/madx
}

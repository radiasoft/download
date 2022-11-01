#!/bin/bash

pyzgoubi_python_install() {
    install_pip_install zgoubi_metadata
    cd PyZgoubi
    codes_python_install
}

pyzgoubi_main() {
    codes_dependencies common
    codes_download https://github.com/PyZgoubi/PyZgoubi.git
    pyzgoubi_patch
}

pyzgoubi_patch() {
    patch zgoubi/core.py <<'EOF'
@@ -67,7 +67,6 @@

 zlog.setLevel(zgoubi_settings['log_level'])

-sys.setcheckinterval(10000)

 zgoubi_module_path = os.path.dirname(os.path.realpath(__file__))
 # something like
EOF
}

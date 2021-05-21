#!/bin/bash

shadow3_main() {
    codes_dependencies xraylib libgfortran4
}

shadow3_python_install() {
    install_pip_install srxraylib shadow3
    install_pip_install --no-deps OASYS1-ShadowOui SYNED
    local p=$(codes_python_lib_dir)/orangecontrib/shadow/util
    echo '# removed by RadiaSoft' > "$p"/__init__.py
    perl -pi -e '/SourceUndulatorFactory(Srw|Pysru)\s*$/ && ($_ = "")' \
         "$p"/undulator/source_undulator.py
}

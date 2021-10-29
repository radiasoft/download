#!/bin/bash

shadow3_main() {
    codes_dependencies xraylib libgfortran4
}

shadow3_python_install() {
    install_pip_install srxraylib shadow3
    install_pip_install --no-deps OASYS1-ShadowOui SYNED OASYS1-ShadowOui-Advanced-Tools
    local p=$(codes_python_lib_dir)/orangecontrib/shadow/util
    echo '# removed by RadiaSoft' > "$p"/__init__.py
    perl -pi -e '/SourceUndulatorFactory(Srw|Pysru)\s*$/ && ($_ = "")' \
         "$p"/undulator/source_undulator.py
    perl -pi -e '/from oasys.*$/ && ($_ = "")' \
         "$p"/shadow_util.py
    local p=$(codes_python_lib_dir)/orangecontrib/shadow_advanced_tools/util
    perl -pi -e '/from oasys.*$/ && ($_ = "")' \
         "$p"/fresnel_zone_plates/fresnel_zone_plate_simulator.py
}

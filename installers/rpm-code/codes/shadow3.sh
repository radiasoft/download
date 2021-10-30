#!/bin/bash

shadow3_main() {
    codes_dependencies xraylib libgfortran4
}

shadow3_python_install() {
    install_pip_install srxraylib shadow3
    install_pip_install --no-deps OASYS1-ShadowOui SYNED OASYS1-ShadowOui-Advanced-Tools
    local p=$(codes_python_lib_dir)/orangecontrib
    local u=$p/shadow/util
    echo '# removed by RadiaSoft' > "$u"/__init__.py
    perl -pi -e '/SourceUndulatorFactory(Srw|Pysru)\s*$/ && ($_ = "")' \
         "$u"/undulator/source_undulator.py
    perl -pi -e '/from oasys.*$/ && ($_ = "")' \
         "$u"/shadow_util.py \
         "$p"/shadow_advanced_tools/util/fresnel_zone_plates/fresnel_zone_plate_simulator.py
}

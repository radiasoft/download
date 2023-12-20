#!/bin/bash

shadow3_main() {
    codes_dependencies common
}

shadow3_python_install() {
    # devel-gfortran-yb66 on 20220603
    install_pip_install srxraylib shadow3
    install_pip_install --no-deps OASYS1-ShadowOui SYNED OASYS1-ShadowOui-Advanced-Tools
    local p=$(codes_python_lib_dir)/orangecontrib
    local u=$p/shadow/util
    echo '# removed by RadiaSoft' > "$u"/__init__.py
    perl -pi -e '/SourceUndulatorFactory(Srw|Pysru)\s*$/ && ($_ = "")' \
         "$u"/undulator/source_undulator.py
    # some of the calls are "try/except", because they are probably having the
    # same issues we are.
    perl -pi -e 's/(from (?:oasys|PyQt5|matplotlib|silx).*)$/pass # $1/' \
         "$u"/shadow_util.py \
         "$p"/shadow_advanced_tools/util/fresnel_zone_plates/fresnel_zone_plate_simulator.py
}

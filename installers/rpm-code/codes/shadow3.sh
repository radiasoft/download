#!/bin/bash

shadow3_main() {
    codes_dependencies common xraylib
}

shadow3_python_install() {
    # devel-gfortran-yb66 on 20220603
    # see also, xraylib.sh
    install_pip_install srxraylib xraylib
    codes_download oasys-kit/shadow3 391b508deb3c4b24249482af1519a0084733b769
    codes_download_module_file pyproject.toml
    codes_download_module_file CMakeLists.txt
    codes_download_module_file source.patch
    rm -f setup.py
    patch -p0 < source.patch
    # build-system.requires doesn't seem to work for isolation
    install_pip_install 'scikit-build-core>=0.10'
    codes_python_install --no-build-isolation
    # Don't need and might conflict
    pip uninstall -y scikit-build-core
    install_pip_install --no-deps OASYS1-ShadowOui==1.5.229 SYNED==1.0.39 OASYS1-ShadowOui-Advanced-Tools==1.0.133
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

#!/bin/bash

: notes <<'EOF'

If you see the following errors try setting LIBGL_ALWAYS_INDIRECT=1
libGL error: No matching fbConfigs or visuals found
libGL error: failed to load driver: swrast
https://unix.stackexchange.com/questions/589236/libgl-error-no-matching-fbconfigs-or-visuals-found-glxgears-error-docker-cu
https://unix.stackexchange.com/questions/1437/what-does-libgl-always-indirect-1-actually-do

To help debug libgl errors:
LIBGL_DEBUG=verbose

On a Mac if the geant4 GUI appears but the space where the visualization should be is blank you may
need to enable opengl:
https://geant4-forum.web.cern.ch/t/qt-viewer-scene-tree-empty/1207/5 (which links to)
https://services.dartmouth.edu/TDClient/1806/Portal/KB/ArticleDet?ID=89669
EOF

geant4_install_data_download_script() {
    install -m 555 /dev/stdin "${codes_dir[bin]}"/rs_geant4_download_data <<'EOF'
#!/bin/bash
#
# Install data sets for Geant4 from https://cern.ch/geant4-data/datasets
#
set -eou pipefail
_USAGE="usage: $0 dataset-install-directory
You must supply an existing and writable directory where you want the datasets to be installed"

install_d=${1:-}
if [[ ! $install_d || ! -d $install_d || ! -w $install_d ]]; then
    echo "$_USAGE" 1>&2
    exit 1
fi

# Same datasets as geant4 would install with GEANT4_INSTALL_DATA=ON
# https://gitlab.cern.ch/geant4/geant4/-/blob/geant4-11.2-release/cmake/Modules/G4DatasetDefinitions.cmake
declare datasets=(
    G4ABLA.3.3
    G4EMLOW.8.5
    G4ENSDFSTATE.2.3
    G4INCL.1.2
    G4NDL.4.7
    G4PARTICLEXS.4.0
    G4PII.1.3
    G4PhotonEvaporation.5.7
    G4RadioactiveDecay.5.6
    G4RealSurface.2.2
    G4SAIDDATA.2.0
    G4TENDL.1.4
)

for d in "${datasets[@]}"; do
    echo "Installing: $d"
    curl -s -S -L https://cern.ch/geant4-data/datasets/"$d".tar.gz | tar xz --directory="$install_d"
done

cat <<EOF2
You must set 'GEANT4_DATA_DIR=$install_d' when running geant4 for it to find the datsets
For example:
GEANT4_DATA_DIR=$install_d ./exampleB1
EOF2
EOF
}

geant4_main() {
    codes_yum_dependencies expat-devel
    #     qt5-qtbase \
    #     qt5-qtbase-devel
    codes_dependencies common
    codes_download https://gitlab.cern.ch/geant4/geant4/-/archive/v11.2.1/geant4-v11.2.1.tar.gz
    codes_cmake \
        -DCMAKE_INSTALL_LIBDIR="${codes_dir[lib]}" \
        -DCMAKE_INSTALL_PREFIX="${codes_dir[prefix]}" \
        -DGEANT4_BUILD_MULTITHREADED=ON \
        -DGEANT4_USE_OPENGL_X11=OFF \
        -DGEANT4_USE_QT=OFF
    codes_make install
    geant4_install_data_download_script
}

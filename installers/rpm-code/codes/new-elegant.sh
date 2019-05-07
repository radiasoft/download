#!/bin/bash
source ~/.bashrc
set -euo pipefail
sudo dnf install -q -y subversion openmotif-devel motif-devel libXaw-devel libXt-devel libXp-devel tcsh
export EPICS_HOST_ARCH=linux-x86_64
export MOTIF_LIB=/usr/lib64
export X11_LIB=/usr/lib64
export MPI_PATH=$(dirname $(type -p mpicc))/
rm -rf oagsoftware
mkdir oagsoftware
cd oagsoftware
root_d=$PWD
for f in '' /apps /apps/configure /apps/configure/os /apps/config /apps/src/utils/tools; do
    svn -N -q checkout https://svn.aps.anl.gov/AOP/oag/trunk$f oag$f
done
for f in elegant.2019.1.1 SDDS.4.1 epics.base.configure epics.extensions.configure; do
    curl -s -S -L https://ops.aps.anl.gov/downloads/$f.tar.gz | tar xzf -
done
cd epics/base
base=$PWD
make=( make -j4 EPICS_HOST_ARCH=$EPICS_HOST_ARCH HOME=$HOME )
"${make[@]}"
cd ../extensions/configure
"${make[@]}"
cd $root_d/oag/apps/configure
echo EPICS_BASE=$base >> RELEASE
echo CROSS_COMPILER_TARGET_ARCHS= >> CONFIG
"${make[@]}"
make+=( LINKER_USE_RPATH=NO COMMANDLINE_LIBRARY= )
cd $root_d/epics/extensions/src/SDDS
sdds_make=( "${make[@]}" MOTIF_LIB=$MOTIF_LIB X11_LIB=$X11_LIB SHARED_LIBRARIES=NO )
"${sdds_make[@]}"
"${make[@]}" clean
cd ../../../../oag/apps/src/utils/tools
"${sdds_make[@]}"
"${make[@]}" clean
cd $root_d/epics/extensions/src/SDDS/python
"${make[@]}"
# py3
# "${make[@]}" clean
# "${make[@]}" PYTHON3=1
# ./oagsoftware/epics/extensions/src/SDDS/python/sdds.py
# ./oagsoftware/epics/extensions/lib/linux-x86_64/sddsdatamodule.so

# toolkit:
# oagsoftware/epics/extensions/bin/linux-x86_64/*

# elegant 1 is elegant elegant 2= pelegant gpu-elgant

cd $root_d/oag/apps/src/physics
elegant_make=( "${make[@]}" SHARED_LIBRARIES=NO )
"${elegant_make[@]}"
cd ../xraylib
"${elegant_make[@]}"
cd ../elegant
"${elegant_make[@]}" PATH="$root_d/epics/extensions/bin/$EPICS_HOST_ARCH:$PATH"
cd elegantTools
"${elegant_make[@]}" PATH="$root_d/epics/extensions/bin/$EPICS_HOST_ARCH:$PATH"
cd ../sddsbrightness
"${elegant_make[@]}"
cd $root_d/epics/extensions/src/SDDS/SDDSlib
mpi_make=( "${elegant_make[@]}" MPI=1 MPI_PATH=$MPI_PATH )
"${make[@]}" clean
"${mpi_make[@]}"
cd ../pgapack
"${mpi_make[@]}"
cd ../../../../../oag/apps/src/elegant
"${make[@]}" clean
"${mpi_make[@]}" PATH="$root_d/epics/extensions/bin/$EPICS_HOST_ARCH:$PATH" Pelegant

# $root_depics
# $root_d/oag/apps/bin/linux-x86_64
#
# ./oag/apps/src/physics/spectraCLITemplates/undulatorPinholeFluxKSpectrum.spin =>
#   /usr/local/oag/apps/configData/spectraCLI/undulatorFluxDensityKSpectrum.spin
# ./oag/apps/src/elegant/ringAnalysisTemplates/FrequencyMapDeltaErrorsTemplate.ele
# ./oag/apps/src/elegant/elegantTools/spiffe2elegant.lte
# ./oag/apps/src/elegant/elegantTools/skewResponseCPTemplate.ele
# /usr/local/oag/apps/configData/elegant/ringAnalysisTemplates

#!/bin/bash
#
# Install synergia on hopper
#
hopper_synergia_main() {
    install_info 'Loading modules'
    hopper_synergia_modules='
        module unload darshan
        # Only for build??
        module unload cray-shmem
        module unload xt-asyncpe
        module switch PrgEnv-pgi PrgEnv-gnu
        module load cray-hdf5
        module load craype
        module load gsl
        module load cmake
        module load git
        module load python/2.7.9
        # pytables loads hdf5 which is deprecated and conflicts with cray-hdf5
        module load pytables >& /dev/null
        module unload hdf5
        module load mpi4py
        module load boost
        module load fftw
        # "module load atp" does not set PKG_CONFIG_PATH automatically
        if [[ ! :$PKG_CONFIG_PATH: =~ :$ATP_HOME/lib/pkgconfig: ]]; then
            export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$ATP_HOME/lib/pkgconfig
        fi;'
    eval "$hopper_synergia_modules"
    git clone -q http://cdcvs.fnal.gov/projects/contract-synergia2
    cd contract-synergia2
    git checkout -b devel origin/devel
    ./bootstrap
    # the test is wrong for hopper; Need to set -DFFTW3_LIBRARY_DIRS explicitly
    perl -pi -e 's{^if fftw3.*}{if True:}' packages/{chef_libs,synergia2}.py
    # Spelling of INCLUDEDIR is wrong.
    # This patches the CMakeLists.txt multiple times, because there's no "post_git" command. contractor executes the
    # packages every time is starts. Very strange. Anyway, the FIND_PACKAGE(MPI required) is wrong. We don't
    # need it, because we specify the compiler explicitly.
    perl -pi -e '
        s{Boost_INCLUDE_DIR}{BOOST_INCLUDEDIR:PATH};
        /Git_clone/ && s{$}{;import subprocess,os;subprocess.call(["perl", "-pi", "-e", "/^FIND_.*MPI/ && s{^}{#}", "build/synergia2/CMakeLists.txt"], stderr=open(os.devnull, "w"))}
        ' packages/synergia2.py
    # Temporary, because sourceforge was barking
    perl -pi -e 's{http://source.*}{https://depot.radiasoft.org/foss/pyparsing-1.5.5.tar.gz"}' packages/pyparsing_pkg.py
    # Basic configuration seems to work. Requires a number of environment variables to be set (extra_envs)
    ./contract.py --configure-import configs/synergia_config_hopper
    # Barnacle.hpp fails to be found (sometimes) if you parallel build chef-libs
    # Not sure if all these extra_envs are needed, but environment variables aren't automatically
    # passed through. We use our patched chef-libs, because the default one is broken.
    ./contract.py --configure \
        "extra_envs=GCC_PATH=$GCC_PATH,FFTW_DIR=$FFTW_DIR,FFTW_INC=$FFTW_INC,ASYNCPE_DIR=/opt/cray/craype/default,BOOST_DIR=$BOOST_DIR,MPICH_DIR=$MPICH_DIR,GSL_DIR=$GSL_DIR" \
        chef-libs/repo=https://github.com/radiasoft/accelerator-modeling-chef.git \
        chef-libs/branch=radiasoft-devel \
        boost/lib="$BOOST_DIR"/libs \
        boost/include="$BOOST_DIR"/boost \
        chef-libs/make_use_custom_parallel=1 \
        chef-libs/make_custom_parallel=1
    ./contract.py
    echo "$hopper_synergia_modules" > setup.d/00-modules.sh
    install_log "Done. Don't forget to ./setup.sh to setup the environment"
}

hopper_synergia_main

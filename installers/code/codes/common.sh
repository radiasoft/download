#!/bin/bash
# Some rpms most codes use
_common_yum=(
    atlas-devel
    blas-devel
    boost-static
    cmake
    eigen3-devel
    flex
    glib2-devel
    hdf5-devel
    hdf5-openmpi
    hdf5-openmpi-devel
    hdf5-openmpi-static
    lapack-devel
    libtool
    llvm-libs
    openmpi-devel
)
codes_yum install "${_common_yum[@]}"
unset _common_yum

# Just in case this is installed outside the context for radiasoft/python2,
# we need openmpi in our path (normally set by ~/.bashrc)
if [[ ! ( :$PATH: =~ :/usr/lib64/openmpi/bin: ) ]]; then
    export PATH=/usr/lib64/openmpi/bin:"$PATH"
fi

# some setup.py's fail if numpy not installed before calling python setup.py
# Last known working version is 1.9.3. pypi-shadow3 setup fails with:
#
#   File "/home/vagrant/.pyenv/versions/2.7.10/lib/python2.7/site-packages/numpy/distutils/command/build_clib.py", line 52, in finalize_options
#     self.set_undefined_options('build', ('parallel', 'parallel'))
#   File "/home/vagrant/.pyenv/versions/2.7.10/lib/python2.7/distutils/cmd.py", line 303, in set_undefined_options
#     getattr(src_cmd_obj, src_option))
#   File "/home/vagrant/.pyenv/versions/2.7.10/lib/python2.7/distutils/cmd.py", line 105, in __getattr__
#     raise AttributeError, attr
#   AttributeError: parallel
# Seems that set_undefined_options looks up the command by name ("build") and
# doesn't get numpy.distutils.command.build, which has "parallel".
# Tried adding numpy.distutils.core.setup to pksetup.setup, and that
# resulted in:
#   AttributeError: py_modules_dict
# No time to debug now.
#pip install numpy==1.9.3
#TODO(pjm): trying latest numpy now, 09/29/17
pip install numpy
pip install matplotlib
pip install scipy
#pip install 'ipython[all]'
# Need to install Cython first, or h5py build fails
pip install Cython
pip install h5py
pip install tables==3.3.0
codes_dependencies pykern
codes_dependencies mpi4py

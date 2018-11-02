#!/bin/bash
# needed for fftw and uti_*.py
codes_dependencies srw
codes_download ochubar/Radia
rm -rf ext_lib
cores=$(codes_num_cores)
perl -pi -e "s/-j\\s*8/-j$cores/" Makefile
perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
make core
make pylib
d=$(python -c 'import distutils.sysconfig as s; print s.get_python_lib()')
(
    cd env/radia_python
    # do not install uti_* because get those from SRW
    install -m 644 *.py radia.so "$d"
)

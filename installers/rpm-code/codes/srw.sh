#!/bin/bash
codes_yum_dependencies fftw2-devel
codes_dependencies bnlcrl
codes_download ochubar/SRW
cores=$(codes_num_cores)
perl -pi -e "s/-j8/-j$cores/" Makefile
perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
make
d=$(python -c 'import distutils.sysconfig as s; print s.get_python_lib()')
(
    cd env/work/srw_python
    install -m 644 {srwl,uti}*.py srwlpy.so "$d"
)

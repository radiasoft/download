#!/bin/bash
# needed for fftw and uti_*.py
codes_dependencies srw
# ochubar/Radia is over 1G so GitHub times out sometimes. This is a
# stripped down copy
codes_download Radia-light '' Radia
# unlike SRW-light, we hacked the Makefiles and setup.py
# if compiles fail, maybe go back to code in srw.sh
codes_make_install all
d=$(python -c 'import distutils.sysconfig as s; print s.get_python_lib()')
(
    cd env/radia_python
    # do not install uti_* because get those from SRW
    install -m 644 *.py radia.so "$d"
)

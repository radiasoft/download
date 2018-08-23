#!/bin/bash
codes_dependencies  Forthon pygist openPMD
# May only be needed for diags in warp init warp_script.py
pip install python-dateutil
warp_pwd=$PWD
# Current build 8/24/2017 not working
codes_download https://bitbucket.org/radiasoft/warp.git
cd pywarp90
if [[ ${codes_debug:-} ]]; then
    perl -pi -e 's{^FARGS.*}{FARGS=--farg -fcheck=all}' Makefile.Forthon
    perl -pi -e 's{(?=-DMPI)}{-fcheck=all }' Makefile.Forthon.pympi
fi
codes_make_install clean install
cat > setup.local.py <<'EOF'
if parallel:
    import os, re
    r = re.compile('^-l(.+)', flags=re.IGNORECASE)
    for x in os.popen('mpifort --showme:link').read().split():
        m = r.match(x)
        if not m:
            continue
        arg = m.group(1)
        if x[1] == 'L':
             library_dirs.append(arg)
             extra_link_args += ['-Wl,-rpath', '-Wl,' + arg]
        else:
             libraries.append(arg)
EOF
codes_make_install FCOMP="-F gfortran --fcompexec mpifort" pclean pinstall

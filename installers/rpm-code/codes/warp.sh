#!/bin/bash

warp_python_install() {
    # May only be needed for diags in warp init warp_script.py
    cd warp/pywarp90
    codes_make_install clean install
    codes_make_install FCOMP="-F gfortran --fcompexec mpifort" pclean pinstall
    cd ../..
    x=$(mpiexec -n 2 python -c 'import warp' 2>&1)
    if [[ ! $x =~ '# 2 proc' ]]; then
        codes_err "mpiexec failed for warp: $x"
    fi
}

warp_main() {
    codes_dependencies common forthon pygist openpmd
    # https://github.com/radiasoft/download/issues/141
    codes_download https://bitbucket.org/radiasoft/warp.git 4ebb54f21373d41b8b1abe2f7a6011896324907f
    cd pywarp90
    if [[ ${codes_debug:-} ]]; then
        perl -pi -e 's{^FARGS.*}{FARGS=--farg -fcheck=all}' Makefile.Forthon3 Makefile.Forthon3.pympi
    else
        perl -pi -e 's{^FARGS.*}{FARGS=--farg -fallow-argument-mismatch}' Makefile.Forthon3 Makefile.Forthon3.pympi
    fi
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
}

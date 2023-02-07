#!/bin/bash

# warp_python_install() {
#     warp_patch_numpy
#     cd warp/pywarp90
#     make cleanall
#     rm -f *local*
#     echo 'FARGS=--farg -fallow-argument-mismatch' >> Makefile.local3
#     echo 'FCOMP=-F gfortran' >> Makefile.local3
#     echo 'FARGS=--farg -fallow-argument-mismatch' >> Makefile.local3.pympi
#     echo 'FCOMP=-F gfortran' >> Makefile.local3.pympi
#     echo 'FCOMPEXEC=--fcompexec mpifort' >> Makefile.local3.pympi
#     make install
#     make clean
#     make pinstall
#     make pclean
# }

# warp_main() {
#     codes_dependencies common forthon pygist openpmd
#     codes_download https://bitbucket.org/berkeleylab/warp.git 3c51c0c94aac8689e16a5948b473c8fa82950b64
#     cd pywarp90
# }

# warp_patch_makefiles() {
#     patch Makefile.Forthon3  <<'EOF'
# @@ -1,12 +1,12 @@
#  DEBUG = #-g --farg "-O0"
# -FARGS =
# -FCOMP =
# +FARGS = --farg -fallow-argument-mismatch
# +FCOMP = -F gfortran
#  FCOMPEXEC =
#  SO = so
#  VERBOSE = #-v
#  FORTHON = Forthon3
#  PYTHON = python3
# -BUILDBASEDIR = build3
# +BUILDBASEDIR = build
#  TEMPBUILDDIR = $(BUILDBASEDIR)/temp
#  INSTALLOPTIONS = #--user
#  -include Makefile.local3
# @@ -14,7 +14,7 @@
#  INSTALLARGS = --pkgbase warp $(BUILDBASE)

#  install: $(TEMPBUILDDIR)/toppydep $(TEMPBUILDDIR)/envpydep $(TEMPBUILDDIR)/w3dpydep $(TEMPBUILDDIR)/f3dpydep $(TEMPBUILDDIR)/wxypydep $(TEMPBUILDDIR)/fxypydep $(TEMPBUILDDIR)/wrzpydep $(TEMPBUILDDIR)/frzpydep $(TEMPBUILDDIR)/herpydep $(TEMPBUILDDIR)/cirpydep $(TEMPBUILDDIR)/chopydep $(TEMPBUILDDIR)/em3dpydep ranffortran.c
# -	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) build $(BUILDBASE) install $(INSTALLOPTIONS)
# +	pip install .

#  build: $(TEMPBUILDDIR)/toppydep $(TEMPBUILDDIR)/envpydep $(TEMPBUILDDIR)/w3dpydep $(TEMPBUILDDIR)/f3dpydep $(TEMPBUILDDIR)/wxypydep $(TEMPBUILDDIR)/fxypydep $(TEMPBUILDDIR)/wrzpydep $(TEMPBUILDDIR)/frzpydep $(TEMPBUILDDIR)/herpydep $(TEMPBUILDDIR)/cirpydep $(TEMPBUILDDIR)/chopydep $(TEMPBUILDDIR)/em3dpydep ranffortran.c
#  	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) build $(BUILDBASE)
# @@ -76,4 +76,3 @@

#  clean:
#  	rm -rf $(BUILDBASEDIR) dist warp.egg-info *.o ../scripts/__version__.py
# -
# EOF

#     patch Makefile.Forthon3.pympi  <<'EOF'
# @@ -1,12 +1,12 @@
#  DEBUG = #-g --farg "-O0"
# -FARGS = #--farg "-I/usr/local/mpi/include"
# -FCOMP =
# +FARGS = --farg -fallow-argument-mismatch
# +FCOMP = -F gfortran
#  FCOMPEXEC = --fcompexec mpifort
#  SO = so
#  VERBOSE = #-v
#  FORTHON = Forthon3
#  PYTHON = python3
# -BUILDBASEDIR = build3
# +BUILDBASEDIR = build
#  INSTALLOPTIONS = #--user
#  -include Makefile.local3.pympi
#  BUILDBASE = --build-base $(BUILDBASEDIR)
# @@ -15,7 +15,7 @@
#  MPIPARALLEL = --farg "-DMPIPARALLEL"

#  install: $(TEMPBUILDDIR)/topparallelpydep $(TEMPBUILDDIR)/envparallelpydep $(TEMPBUILDDIR)/w3dparallelpydep $(TEMPBUILDDIR)/f3dparallelpydep $(TEMPBUILDDIR)/wxyparallelpydep $(TEMPBUILDDIR)/fxyparallelpydep $(TEMPBUILDDIR)/wrzparallelpydep $(TEMPBUILDDIR)/frzparallelpydep $(TEMPBUILDDIR)/herparallelpydep $(TEMPBUILDDIR)/cirparallelpydep $(TEMPBUILDDIR)/choparallelpydep $(TEMPBUILDDIR)/em3dparallelpydep ranffortran.c
# -	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) --parallel build $(BUILDBASE) install $(INSTALLOPTIONS)
# +	pip install --ignore-installed .

#  build: $(TEMPBUILDDIR)/topparallelpydep $(TEMPBUILDDIR)/envparallelpydep $(TEMPBUILDDIR)/w3dparallelpydep $(TEMPBUILDDIR)/f3dparallelpydep $(TEMPBUILDDIR)/wxyparallelpydep $(TEMPBUILDDIR)/fxyparallelpydep $(TEMPBUILDDIR)/wrzparallelpydep $(TEMPBUILDDIR)/frzparallelpydep $(TEMPBUILDDIR)/herparallelpydep $(TEMPBUILDDIR)/cirparallelpydep $(TEMPBUILDDIR)/choparallelpydep $(TEMPBUILDDIR)/em3dparallelpydep ranffortran.c
#  	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) --parallel build $(BUILDBASE)
# @@ -77,4 +77,3 @@

#  clean:
#  	rm -rf $(BUILDBASEDIR) dist warp.egg-info *.o ../scripts/__version__.py
# -
# EOF
# }

# warp_patch_numpy() {
#     perl -pi -e 's/np\.int/np.int_/' $(find . -name '*.py')
# }

# warp_patch_parallel_setup_py() {
#     patch setup.py <<'EOF'
# @@ -18,9 +18,9 @@

#  machine = sys.platform
#  debug   = 0
# -fcomp   = None
# -parallel = 0
# -fcompexec = None
# +fcomp = 'gfortran'
# +parallel = 1
# +fcompexec = 'mpifort'
#  mpifort_compiler = None
#  for o in optlist:
#      if   o[0] == '-g': debug = 1
# EOF
# }
#!/bin/bash

warp_python_install() {
    python -m lib2to3 --no-diffs --write --nobackups  --processes=4 .
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
#     cat > setup.local.py <<'EOF'
# if parallel:
#     import os, re
#     r = re.compile('^-l(.+)', flags=re.IGNORECASE)
#     for x in os.popen('mpifort --showme:link').read().split():
#         m = r.match(x)
#         if not m:
#             continue
#         arg = m.group(1)
#         if x[1] == 'L':
#              library_dirs.append(arg)
#              extra_link_args += ['-Wl,-rpath', '-Wl,' + arg]
#         else:
#              libraries.append(arg)
# EOF

}

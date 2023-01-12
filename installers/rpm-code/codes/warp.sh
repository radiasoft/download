#!/bin/bash

warp_python_install() {
    cd warp/pywarp90
    warp_patch_makefiles
    make install
    make clean
    warp_patch_parallel_setup_py
    make pinstall
    cd ../..
    x=$(mpiexec -n 2 python -c 'import warp' 2>&1)
    if [[ ! $x =~ '# 2 proc' ]]; then
        codes_err "mpiexec failed for warp: $x"
    fi
}

warp_main() {
    codes_dependencies common forthon pygist openpmd
    codes_download https://bitbucket.org/berkeleylab/warp.git c1c0d155fadba42849547641c2dfcb6e5d23ce02
    cd pywarp90
}

warp_patch_makefiles() {
    patch Makefile.Forthon3  <<'EOF'
@@ -1,12 +1,12 @@
 DEBUG = #-g --farg "-O0"
-FARGS =
-FCOMP =
+FARGS = --farg -fallow-argument-mismatch
+FCOMP = -F gfortran
 FCOMPEXEC =
 SO = so
 VERBOSE = #-v
 FORTHON = Forthon3
 PYTHON = python3
-BUILDBASEDIR = build3
+BUILDBASEDIR = build
 TEMPBUILDDIR = $(BUILDBASEDIR)/temp
 INSTALLOPTIONS = #--user
 -include Makefile.local3
@@ -14,7 +14,7 @@
 INSTALLARGS = --pkgbase warp $(BUILDBASE)

 install: $(TEMPBUILDDIR)/toppydep $(TEMPBUILDDIR)/envpydep $(TEMPBUILDDIR)/w3dpydep $(TEMPBUILDDIR)/f3dpydep $(TEMPBUILDDIR)/wxypydep $(TEMPBUILDDIR)/fxypydep $(TEMPBUILDDIR)/wrzpydep $(TEMPBUILDDIR)/frzpydep $(TEMPBUILDDIR)/herpydep $(TEMPBUILDDIR)/cirpydep $(TEMPBUILDDIR)/chopydep $(TEMPBUILDDIR)/em3dpydep ranffortran.c
-	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) build $(BUILDBASE) install $(INSTALLOPTIONS)
+	pip install .

 build: $(TEMPBUILDDIR)/toppydep $(TEMPBUILDDIR)/envpydep $(TEMPBUILDDIR)/w3dpydep $(TEMPBUILDDIR)/f3dpydep $(TEMPBUILDDIR)/wxypydep $(TEMPBUILDDIR)/fxypydep $(TEMPBUILDDIR)/wrzpydep $(TEMPBUILDDIR)/frzpydep $(TEMPBUILDDIR)/herpydep $(TEMPBUILDDIR)/cirpydep $(TEMPBUILDDIR)/chopydep $(TEMPBUILDDIR)/em3dpydep ranffortran.c
 	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) build $(BUILDBASE)
@@ -76,4 +76,3 @@

 clean:
 	rm -rf $(BUILDBASEDIR) dist warp.egg-info *.o ../scripts/__version__.py
-
EOF

    patch Makefile.Forthon3.pympi  <<'EOF'
@@ -1,12 +1,12 @@
 DEBUG = #-g --farg "-O0"
-FARGS = #--farg "-I/usr/local/mpi/include"
-FCOMP =
+FARGS = --farg -fallow-argument-mismatch
+FCOMP = -F gfortran
 FCOMPEXEC = --fcompexec mpifort
 SO = so
 VERBOSE = #-v
 FORTHON = Forthon3
 PYTHON = python3
-BUILDBASEDIR = build3
+BUILDBASEDIR = build
 INSTALLOPTIONS = #--user
 -include Makefile.local3.pympi
 BUILDBASE = --build-base $(BUILDBASEDIR)
@@ -15,7 +15,7 @@
 MPIPARALLEL = --farg "-DMPIPARALLEL"

 install: $(TEMPBUILDDIR)/topparallelpydep $(TEMPBUILDDIR)/envparallelpydep $(TEMPBUILDDIR)/w3dparallelpydep $(TEMPBUILDDIR)/f3dparallelpydep $(TEMPBUILDDIR)/wxyparallelpydep $(TEMPBUILDDIR)/fxyparallelpydep $(TEMPBUILDDIR)/wrzparallelpydep $(TEMPBUILDDIR)/frzparallelpydep $(TEMPBUILDDIR)/herparallelpydep $(TEMPBUILDDIR)/cirparallelpydep $(TEMPBUILDDIR)/choparallelpydep $(TEMPBUILDDIR)/em3dparallelpydep ranffortran.c
-	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) --parallel build $(BUILDBASE) install $(INSTALLOPTIONS)
+	pip install --ignore-installed .

 build: $(TEMPBUILDDIR)/topparallelpydep $(TEMPBUILDDIR)/envparallelpydep $(TEMPBUILDDIR)/w3dparallelpydep $(TEMPBUILDDIR)/f3dparallelpydep $(TEMPBUILDDIR)/wxyparallelpydep $(TEMPBUILDDIR)/fxyparallelpydep $(TEMPBUILDDIR)/wrzparallelpydep $(TEMPBUILDDIR)/frzparallelpydep $(TEMPBUILDDIR)/herparallelpydep $(TEMPBUILDDIR)/cirparallelpydep $(TEMPBUILDDIR)/choparallelpydep $(TEMPBUILDDIR)/em3dparallelpydep ranffortran.c
 	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) --parallel build $(BUILDBASE)
@@ -77,4 +77,3 @@

 clean:
 	rm -rf $(BUILDBASEDIR) dist warp.egg-info *.o ../scripts/__version__.py
-
EOF
}

warp_patch_parallel_setup_py() {
    patch setup.py <<'EOF'
@@ -18,9 +18,9 @@

 machine = sys.platform
 debug   = 0
-fcomp   = None
-parallel = 0
-fcompexec = None
+fcomp = 'gfortran'
+parallel = 1
+fcompexec = 'mpifort'
 mpifort_compiler = None
 for o in optlist:
     if   o[0] == '-g': debug = 1
EOF
}

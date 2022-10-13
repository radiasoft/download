#!/bin/bash

warp_python_install() {
    # May only be needed for diags in warp init warp_script.py
    cd warp/pywarp90
    warp_patch_makefiles
    warp_patch_serial_setup_py
    codes_make clean
    codes_make_install
    warp_patch_parallel_setup_py
    codes_make clean
    codes_make pinstall
    cd ../..
    x=$(mpiexec -n 2 python -c 'import warp' 2>&1)
    if [[ ! $x =~ '# 2 proc' ]]; then
        codes_err "mpiexec failed for warp: $x"
    fi
}

warp_main() {
    codes_dependencies common forthon pygist openpmd
    codes_download https://bitbucket.org/berkeleylab/warp.git Release_5.0
    cd pywarp90
    if [[ ${codes_debug:-} ]]; then
        perl -pi -e 's{^FARGS.*}{FARGS=--farg -fcheck=all}' Makefile.Forthon3 Makefile.Forthon3.pympi
    else
        perl -pi -e 's{^FARGS.*}{FARGS=--farg -fallow-argument-mismatch}' Makefile.Forthon3 Makefile.Forthon3.pympi
    fi
    cat > setup.local.py <<'EOF'
if parallel:
    libraries = fcompiler.libs + ['mpichf90', 'mpich', 'opa', 'mpl']
EOF
}

warp_patch_makefiles() {
    patch Makefile.Forthon3  <<'EOF'
@@ -1,19 +1,19 @@
 DEBUG = #-g --farg "-O0"
 FARGS=--farg -fallow-argument-mismatch
-FCOMP =
+FCOMP = -F gfortran
 FCOMPEXEC =
 SO = so
 VERBOSE = #-v
 FORTHON = Forthon3
 PYTHON = python3
-BUILDBASEDIR = build3
+BUILDBASEDIR = build
 INSTALLOPTIONS = #--user
 -include Makefile.local3
 BUILDBASE = --build-base $(BUILDBASEDIR)
 INSTALLARGS = --pkgbase warp $(BUILDBASE)

 install: $(BUILDBASEDIR)/toppydep $(BUILDBASEDIR)/envpydep $(BUILDBASEDIR)/w3dpydep $(BUILDBASEDIR)/f3dpydep $(BUILDBASEDIR)/wxypydep $(BUILDBASEDIR)/fxypydep $(BUILDBASEDIR)/wrzpydep $(BUILDBASEDIR)/frzpydep $(BUILDBASEDIR)/herpydep $(BUILDBASEDIR)/cirpydep $(BUILDBASEDIR)/chopydep $(BUILDBASEDIR)/em3dpydep ranffortran.c
-	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) build $(BUILDBASE) install $(INSTALLOPTIONS)
+	pip install .

 build: $(BUILDBASEDIR)/toppydep $(BUILDBASEDIR)/envpydep $(BUILDBASEDIR)/w3dpydep $(BUILDBASEDIR)/f3dpydep $(BUILDBASEDIR)/wxypydep $(BUILDBASEDIR)/fxypydep $(BUILDBASEDIR)/wrzpydep $(BUILDBASEDIR)/frzpydep $(BUILDBASEDIR)/herpydep $(BUILDBASEDIR)/cirpydep $(BUILDBASEDIR)/chopydep $(BUILDBASEDIR)/em3dpydep ranffortran.c
 	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) build $(BUILDBASE)

EOF

    patch Makefile.Forthon3.pympi  <<'EOF'
@@ -1,20 +1,20 @@
 DEBUG = #-g --farg "-O0"
 FARGS=--farg -fallow-argument-mismatch
-FCOMP =
+FCOMP = -F gfortran
 FCOMPEXEC = --fcompexec mpifort
 SO = so
 VERBOSE = #-v
 FORTHON = Forthon3
 PYTHON = python3
-BUILDBASEDIR = build3parallel
+BUILDBASEDIR = build
 INSTALLOPTIONS = #--user
 -include Makefile.local3.pympi
 BUILDBASE = --build-base $(BUILDBASEDIR)
 INSTALLARGS = --pkgbase warp $(BUILDBASE)
-MPIPARALLEL = --farg "-DMPIPARALLEL"
+MPIPARALLEL = --farg "-DMPIPARALLEL -fallow-argument-mismatch"

 install: $(BUILDBASEDIR)/topparallelpydep $(BUILDBASEDIR)/envparallelpydep $(BUILDBASEDIR)/w3dparallelpydep $(BUILDBASEDIR)/f3dparallelpydep $(BUILDBASEDIR)/wxyparallelpydep $(BUILDBASEDIR)/fxyparallelpydep $(BUILDBASEDIR)/wrzparallelpydep $(BUILDBASEDIR)/frzparallelpydep $(BUILDBASEDIR)/herparallelpydep $(BUILDBASEDIR)/cirparallelpydep $(BUILDBASEDIR)/choparallelpydep $(BUILDBASEDIR)/em3dparallelpydep ranffortran.c
-	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) --parallel build $(BUILDBASE) install $(INSTALLOPTIONS)
+	pip install --ignore-installed .

 build: $(BUILDBASEDIR)/topparallelpydep $(BUILDBASEDIR)/envparallelpydep $(BUILDBASEDIR)/w3dparallelpydep $(BUILDBASEDIR)/f3dparallelpydep $(BUILDBASEDIR)/wxyparallelpydep $(BUILDBASEDIR)/fxyparallelpydep $(BUILDBASEDIR)/wrzparallelpydep $(BUILDBASEDIR)/frzparallelpydep $(BUILDBASEDIR)/herparallelpydep $(BUILDBASEDIR)/cirparallelpydep $(BUILDBASEDIR)/choparallelpydep $(BUILDBASEDIR)/em3dparallelpydep ranffortran.c
 	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) --parallel build $(BUILDBASE)

EOF
}

warp_patch_parallel_setup_py() {
    git checkout setup.py
    patch setup.py <<'EOF'
@@ -30,6 +30,9 @@
     elif o[0] == '--fcompexec': fcompexec = o[1]
     elif o[0] == '--mpifort_compiler': mpifort_compiler = o[1]

+parallel = 1
+fcomp = 'gfortran'
+fcompexec = 'mpifort'
 sys.argv = ['setup.py'] + args
 fcompiler = FCompiler(machine = machine,
                       debug = debug,
@@ -172,7 +175,7 @@
                  platforms = 'Linux, Unix, Windows (bash), Mac OSX',
                  ext_modules = [setuptools.Extension('warp.' + name,
                                                      ['warpC_Forthon.c',
-                                                      os.path.join(builddir, 'Forthon.c'),
+                                                      './build/temp.linux-x86_64-cpython-310/Forthon.c',
                                                       'pmath_rng.c', 'ranf.c', 'ranffortran.c'],
                                                      include_dirs = include_dirs,
                                                      library_dirs = library_dirs,

EOF
}

warp_patch_serial_setup_py() {
    patch setup.py <<'EOF'
@@ -30,6 +30,7 @@ for o in optlist:
     elif o[0] == '--fcompexec': fcompexec = o[1]
     elif o[0] == '--mpifort_compiler': mpifort_compiler = o[1]

+fcomp = 'gfortran'
 sys.argv = ['setup.py'] + args
 fcompiler = FCompiler(machine = machine,
                       debug = debug,
@@ -172,7 +173,7 @@ machines that are space-charge dominated.""",
                  platforms = 'Linux, Unix, Windows (bash), Mac OSX',
                  ext_modules = [setuptools.Extension('warp.' + name,
                                                      ['warpC_Forthon.c',
-                                                      os.path.join(builddir, 'Forthon.c'),
+                                                      './build/temp.linux-x86_64-cpython-310/Forthon.c',
                                                       'pmath_rng.c', 'ranf.c', 'ranffortran.c'],
                                                      include_dirs = include_dirs,
                                                      library_dirs = library_dirs,
EOF
}

#!/bin/bash

warp_python_install() {
    cd warp
    warp_py_2_to_3
    warp_patch_numpy
    cd pywarp90
    warp_patch_makefiles
    warp_patch_serial_setup_py
    codes_make install
    warp_patch_parallel_setup_py
    codes_make pinstall
    warp_fix_install
    cd
    x=$(mpiexec -n 2 python -c 'import warp' 2>&1)
    if [[ ! $x =~ '# 2 proc' ]]; then
        codes_err "mpiexec failed for warp: $x"
    fi
}

warp_fix_install() {
    declare w=4.5
    declare p=3.9
    declare v=$(grep -oP "(?<=version = ')\d\.\d(?=')" setup.py )
    if [[ ! "$v" =~ "$w" ]]; then
        codes_err "expecting warp version $w found $v"
    fi
    v="$(codes_python_version)"
    if [[ ! $v =~ $p ]]; then
        codes_err "expecting python version $p found $v"
    fi
    declare l="$(codes_python_lib_dir)"
    declare s="$l/warp-$w-py$p.egg"
    mv "$s"/warp/* "$l/warp"
    declare d
    for d in 'warpoptions' 'warp_parallel'; do
        mv "$s/$d"  "$l"
    done
    rm -rf "$s"
    s="$l/warp-0.0.0-py$p-linux-x86_64.egg/warp"
    mv "$s/"*.{so,py} "$l/warp"
    rm -rf "$(dirname $s)"
    rm "$l"/easy-install.pth
}

warp_main() {
    codes_dependencies common forthon pygist openpmd
    codes_download https://bitbucket.org/radiasoft/warp.git 4ebb54f21373d41b8b1abe2f7a6011896324907f
    cd pywarp90
    cat > setup.local.py <<'EOF'
if parallel:
    libraries = fcompiler.libs + ['mpichf90', 'mpich', 'opa', 'mpl']
EOF
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
 INSTALL = --install
 INSTALLOPTIONS = #--user
 -include Makefile.local3
@@ -17,7 +17,7 @@
 	(cd ../scripts;$(PYTHON) setup.py build $(BUILDBASE) install $(INSTALLOPTIONS))

 installso: $(BUILDBASEDIR)/toppydep $(BUILDBASEDIR)/envpydep $(BUILDBASEDIR)/w3dpydep $(BUILDBASEDIR)/f3dpydep $(BUILDBASEDIR)/wxypydep $(BUILDBASEDIR)/fxypydep $(BUILDBASEDIR)/wrzpydep $(BUILDBASEDIR)/frzpydep $(BUILDBASEDIR)/herpydep $(BUILDBASEDIR)/cirpydep $(BUILDBASEDIR)/chopydep $(BUILDBASEDIR)/em3dpydep ranffortran.c
-	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) build $(BUILDBASE) install $(INSTALLOPTIONS)
+	pip install .

 build: $(BUILDBASEDIR)/toppydep $(BUILDBASEDIR)/envpydep $(BUILDBASEDIR)/w3dpydep $(BUILDBASEDIR)/f3dpydep $(BUILDBASEDIR)/wxypydep $(BUILDBASEDIR)/fxypydep $(BUILDBASEDIR)/wrzpydep $(BUILDBASEDIR)/frzpydep $(BUILDBASEDIR)/herpydep $(BUILDBASEDIR)/cirpydep $(BUILDBASEDIR)/chopydep $(BUILDBASEDIR)/em3dpydep ranffortran.c
 	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) build $(BUILDBASE)
@@ -79,4 +79,3 @@

 clean:
 	rm -rf $(BUILDBASEDIR) *.o ../scripts/$(BUILDBASEDIR) ../scripts/__version__.py
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
-BUILDBASEDIR = build3parallel
+BUILDBASEDIR = buildparallel
 INSTALL = --install
 INSTALLOPTIONS = #--user
 -include Makefile.local3.pympi
@@ -18,7 +18,7 @@
 	(cd ../scripts;$(PYTHON) setup.py build $(BUILDBASE) install $(INSTALLOPTIONS))

 installso: $(BUILDBASEDIR)/topparallelpydep $(BUILDBASEDIR)/envparallelpydep $(BUILDBASEDIR)/w3dparallelpydep $(BUILDBASEDIR)/f3dparallelpydep $(BUILDBASEDIR)/wxyparallelpydep $(BUILDBASEDIR)/fxyparallelpydep $(BUILDBASEDIR)/wrzparallelpydep $(BUILDBASEDIR)/frzparallelpydep $(BUILDBASEDIR)/herparallelpydep $(BUILDBASEDIR)/cirparallelpydep $(BUILDBASEDIR)/choparallelpydep $(BUILDBASEDIR)/em3dparallelpydep ranffortran.c
-	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) --parallel build $(BUILDBASE) install $(INSTALLOPTIONS)
+	pip install .

 build: $(BUILDBASEDIR)/topparallelpydep $(BUILDBASEDIR)/envparallelpydep $(BUILDBASEDIR)/w3dparallelpydep $(BUILDBASEDIR)/f3dparallelpydep $(BUILDBASEDIR)/wxyparallelpydep $(BUILDBASEDIR)/fxyparallelpydep $(BUILDBASEDIR)/wrzparallelpydep $(BUILDBASEDIR)/frzparallelpydep $(BUILDBASEDIR)/herparallelpydep $(BUILDBASEDIR)/cirparallelpydep $(BUILDBASEDIR)/choparallelpydep $(BUILDBASEDIR)/em3dparallelpydep ranffortran.c
 	$(PYTHON) setup.py $(FCOMP) $(FCOMPEXEC) --parallel build $(BUILDBASE)
@@ -80,4 +80,3 @@

 clean:
 	rm -rf $(BUILDBASEDIR) *.o ../scripts/$(BUILDBASEDIR) ../scripts/__version__.py
-
EOF
}

warp_patch_numpy() {
    perl -pi -e 's/np\.int/np.int_/' $(find . -name '*.py')
}

warp_patch_parallel_setup_py() {
    git checkout setup.py
    patch setup.py <<'EOF'
@@ -21,9 +21,9 @@

 machine = sys.platform
 debug   = 0
-fcomp   = None
-parallel = 0
-fcompexec = None
+fcomp   = 'gfortran'
+parallel = 1
+fcompexec = 'mpifort'
 for o in optlist:
     if   o[0] == '-g': debug = 1
     elif o[0] == '-t': machine = o[1]
@@ -173,7 +173,7 @@
        platforms = 'Linux, Unix, Windows (bash), Mac OSX',
        ext_modules = [Extension('warp.' + name,
                                 ['warpC_Forthon.c',
-                                 os.path.join(builddir, 'Forthon.c'),
+                                './buildparallel/temp.linux-x86_64-cpython-39/Forthon.c',
                                  'pmath_rng.c', 'ranf.c', 'ranffortran.c'],
                                 include_dirs=include_dirs,
                                 library_dirs=library_dirs,
EOF
}

warp_patch_serial_setup_py() {
    patch setup.py <<'EOF'
@@ -21,7 +21,7 @@

 machine = sys.platform
 debug   = 0
-fcomp   = None
+fcomp   = 'gfortran'
 parallel = 0
 fcompexec = None
 for o in optlist:
@@ -173,7 +173,7 @@
        platforms = 'Linux, Unix, Windows (bash), Mac OSX',
        ext_modules = [Extension('warp.' + name,
                                 ['warpC_Forthon.c',
-                                 os.path.join(builddir, 'Forthon.c'),
+                                 './build/temp.linux-x86_64-cpython-39/Forthon.c',
                                  'pmath_rng.c', 'ranf.c', 'ranffortran.c'],
                                 include_dirs=include_dirs,
                                 library_dirs=library_dirs,
EOF
}

warp_py_2_to_3() {
    python -m lib2to3 --write --no-diffs --nobackups .
    # Fix incorrect lib2to3 changes
    declare s
    for s in 's/from . import warpoptions/import warpoptions/' \
        's/from .warp_parallel import \*/from warp_parallel import */' \
        's/from . import warp_parallel/import warp_parallel/' \
        's/import __version__/from . import __version__/' \
    ; do
        perl -pi -e "$s" "./scripts/warp.py"
    done
}

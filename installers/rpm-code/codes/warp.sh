#!/bin/bash

warp_python_install() {
    warp_prereq
    codes_download https://bitbucket.org/berkeleylab/warp.git
    warp_patch_numpy
    cd pywarp90
    warp_local
    # Parallel makes sometimes fail
    make install
    make pinstall
}

warp_local() {
    cat > setup.local.py <<'EOF'
if parallel:
    libraries = fcompiler.libs + ['mpichf90', 'mpich', 'opa', 'mpl']
EOF
    cat > Makefile.local.pympi <<'EOF'
FCOMP= -F gfortran
EOF

}
warp_main() {
    codes_dependencies common
}

warp_patch_numpy() {
    perl -pi -e 's/\bnp\.int\b/np.int64/' $(find . -name '*.py')
}

warp_prereq() {
    install_pip_install Forthon==0.10.9 openPMD-viewer==1.11.0
    warp_prereq_pygist
}

warp_prereq_pygist() {
    codes_download https://bitbucket.org/dpgrote/pygist.git a3601a80aeccc2e63ece23c603281d689cb67576
    warp_prereq_pygist_patch
    python setup.py config
    python setup.py build
    codes_python_install --no-build-isolation
}

warp_prereq_pygist_patch() {
    patch src/play/unix/fputest.c <<'EOF'
diff --git a/src/play/unix/fputest.c b/src/play/unix/fputest.c
index b56702a..aaf8c08 100644
--- a/src/play/unix/fputest.c
+++ b/src/play/unix/fputest.c
@@ -19,6 +19,7 @@ void u_fpu_setup(int when) {}
 #include <stdio.h>
 #include <stdlib.h>
 #include <signal.h>
+#include <string.h>

 #include <setjmp.h>
 static jmp_buf u_jmp_target;
@@ -43,7 +44,14 @@ main(int argc, char *argv[])

   /* signal *ought* to be enough to get SIGFPE delivered
    * -- but it never is -- see README.fpu */
-  signal(SIGFPE, &u_sigfpe);
+
+  struct sigaction act;
+  struct sigaction oldact;
+  memset(&act, 0, sizeof(act));
+  act.sa_handler = u_sigfpe;
+  act.sa_flags = SA_NODEFER | SA_NOMASK;
+  sigaction(SIGFPE, &act, &oldact);
+

   /* need to make sure that loop index i actually decrements
    * despite interrupt */
@@ -90,7 +98,6 @@ u_sigfpe(int sig)
 {
   if (sig==SIGFPE) {
     u_fpu_setup(1);
-    signal(SIGFPE, &u_sigfpe);
     longjmp(u_jmp_target, 1);
   } else {
     puts("u_sigfpe called, but with bad parameter");

EOF
}

tmp_ignore_warp_test() {
    # We want to see the error so '|| true'
    x=$(mpiexec -n 2 python -c 'import warp' 2>&1 || true)
    if [[ ! $x =~ '# 2 proc' ]]; then
        codes_err "mpiexec failed for warp: $x"
    fi
}

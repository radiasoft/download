#!/bin/bash

pygist_python_install() {
    cd pygist
    python setup.py config
    python setup.py build
    codes_python_install
}

pygist_main() {
    codes_dependencies common
    codes_download https://bitbucket.org/dpgrote/pygist.git
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

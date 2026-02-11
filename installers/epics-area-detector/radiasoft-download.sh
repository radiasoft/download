#!/bin/bash
#
# This file is sourced from build.sh so setup is there.
#
# Install epics, asyn, and synaps
#
_asyn_version=R4-45
_epics_version=7.0.8.1
_synapps_version=R6-3

_epics_base() {
    declare d=$(dirname "$EPICS_BASE")
    mkdir -p "$d"
    cd "$d"
    b=base-"$_epics_version"
    _epics_untar https://epics-controls.org/download/base/"$b".tar.gz "$b" "$EPICS_BASE"
    cd "$EPICS_BASE"
    make -j4
}

_epics_main() {
    declare p=$PWD
    install_source_bashrc
    bivio_path_remove "$EPICS_BASE"/bin
    # re2c is for synapps; rpcgen and libtirpc-devel is for asyn; ExtUtils for busy
    install_yum_install libtirpc-devel re2c rpcgen perl-ExtUtils-Command
    # perl-FindBin \
    if rpm -q rscode-epics &> /dev/null; then
        # development VM build already has epics, not inside install_main
        cd "$EPICS_BASE"
    else
        # Inside a container build, need epics
        _epics_base
    fi
    mkdir -p extensions
    cd extensions
    _epics_synapps
    # Need to return, because this file is sourced
    cd "$p"
}

_epics_synapps() {
    declare d=synApps
    # Must be absolute or fails silently
    declare f=$PWD/$d.modules
    cat <<'EOF' > "$f"
AREA_DETECTOR=R3-12-1
ASYN=R4-44-2
AUTOSAVE=R5-11
BUSY=R1-7-4
CALC=R3-7-5
DEVIOCSTATS=3.1.16
SNCSEQ=R2-2-9
SSCAN=R2-11-6
EOF
    curl -s -S -L https://github.com/EPICS-synApps/assemble_synApps/releases/download/"$_synapps_version"/assemble_synApps \
        | perl - --base="$EPICS_BASE" --dir="$d" --config="$f"
    rm "$f"
    cd "$d"/support
    _epics_synapps_patch
    make -j 4
    # POSIT used by slicops-demo.sh
    export sim_det_dir=$(find "$PWD" -type d -path '*iocBoot/iocSimDetector')
    cd - >& /dev/null
}

_epics_synapps_patch() {
    perl -pi -e '$. == 1 && ($_ .= qq{USR_CFLAGS += -Wno-error=incompatible-pointer-types\n})' */configure/CONFIG_SITE
    perl -pi -e 's{void Find.*\(\).*}{}' sequencer-mirror-R2-2-9/src/lemon/lemon.c
    perl -pi -e 's{(?<=static void monitor\()\)}{scanparmRecord *psr)}' sscan-R2-11-6/sscanApp/src/scanparmRecord.c
    perl -pi -e 's{(static long \w+)\(\)}{$1(busyRecord *)}' busy-R1-7-4/busyApp/src/devBusySoft{,Raw}.c
    perl -pi -e 's{(static long \w+)\(\)}{$1(busyRecord *)}' busy-R1-7-4/busyApp/src/devBusySoft{,Raw}.c

    perl -pi -e '
        s{(?<=checkLinks\()\);}{struct transformRecord *ptran);};
        s{(?<=checkLinksCallback\()\);}{CALLBACK *pcallback);};
        s{(?<=monitor\()\);}{transformRecord *ptran);};
        s{(?<=checkAlarms\()\);}{transformRecord *ptran);};
        s{(?<=get_precision\()\);}{const DBADDR *paddr, long *precision);};
        s{(?<=special\()\);}{const DBADDR *paddr, int after);};
        s{(?<=process\()\);}{dbCommon *pcommon);};
        s{(?<=init_record\()\);}{dbCommon *pcommon, int pass);};
    ' calc-R3-7-5/calcApp/src/transformRecord.c
    patch asyn-R4-44-2/asyn/devGpib/devCommonGpib.c <<'EOF'
@@ -51,7 +51,8 @@ long  devGpib_initAi(aiRecord * pai)
     long result;
     int cmdType;
     gpibDpvt *pgpibDpvt;
-    DEVSUPFUN  got_special_linconv = ((gDset *) pai->dset)->funPtr[5];
+    typedef void (*slicops_fix)(aiRecord *, int);
+    slicops_fix got_special_linconv = (slicops_fix)((gDset *) pai->dset)->funPtr[5];

     result = pdevSupportGpib->initRecord((dbCommon *) pai, &pai->inp);
     if(result) return result;
@@ -130,7 +131,8 @@ long  devGpib_initAo(aoRecord * pao)
     long result;
     int cmdType;
     gpibDpvt *pgpibDpvt;
-    DEVSUPFUN  got_special_linconv = ((gDset *) pao->dset)->funPtr[5];
+    typedef void (*slicops_fix)(aoRecord *, int);
+    slicops_fix got_special_linconv = (slicops_fix)((gDset *) pao->dset)->funPtr[5];

     /* do common initialization */
     result = pdevSupportGpib->initRecord((dbCommon *) pao, &pao->out);
EOF
    patch busy-R1-7-4/busyApp/src/busyRecord.c <<'EOF'
@@ -82,13 +82,14 @@ rset busyRSET={
 };
 epicsExportAddress(rset,busyRSET);

+typedef long (*slicops_fix)(busyRecord *);
 struct busydset { /* busyRecord dset */
     long         number;
     DEVSUPFUN    dev_report;
     DEVSUPFUN    init;
-    DEVSUPFUN    init_record;  /*returns:(0,2)=>(success,success no convert*/
+    slicops_fix    init_record;  /*returns:(0,2)=>(success,success no convert*/
     DEVSUPFUN    get_ioint_info;
-    DEVSUPFUN    write_busy;/*returns: (-1,0)=>(failure,success)*/
+    slicops_fix    write_busy;/*returns: (-1,0)=>(failure,success)*/
 };


EOF
    patch sscan-R2-11-6/sscanApp/src/writeXDR.c << 'EOF'
@@ -159,12 +159,14 @@ int writeXDR_bytes(FILE *fd, void *addr, size_t len) {
 int writeXDR_vector(FILE *fd, char *basep, int nelem, int elemsize, xdrproc_t xdr_elem) {
 	int i;
 	char *elptr;
+        typedef int (*slicops_fix)(FILE *, char*);
+        slicops_fix xdr_elem_fix = (slicops_fix)xdr_elem;

 	elptr = basep;
 	for (i = 0; i < nelem; i++) {
-		if (! (*xdr_elem)(fd, elptr)) {
+		if (! (*xdr_elem_fix)(fd, elptr)) {
 			return(0);
 		}
 		elptr += elemsize;
 	}
EOF
}

_epics_untar() {
    declare url=$1
    declare base=$2
    declare tgt=$3
    curl -L -s -S "$url" | tar xzf -
    mv "$base" "$tgt"
    cd "$tgt"
}

# No "$@" since this file is sourced from build.sh (this would pass args from program)
_epics_main

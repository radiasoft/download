#!/bin/bash
set -euo pipefail

_flash_tarball_version=4.7.1

flash_tarball_main() {
    declare d=$PWD/proprietary
    declare t=$d/FLASH$_flash_tarball_version.tar.gz
    if [[ ! -f $t ]]; then
            install_err "$t must exist"
    fi
    install_tmp_dir
    declare p=$PWD
    declare r=()
    install_url radiasoft/download installers
    install_script_eval rpm-code/codes.sh
    codes_download flashcap
    git fetch --unshallow
    declare x
    for x in \
        'CapLaser3D 47a641aa467ff48c1337a69e6c3a6778e5b854ae' \
        'CapLaserBELLA master' \
    ; do
        x=( $x )
        git checkout --quiet "${x[1]}"
        cd "config/${x[0]}"
        # POSIT: Matches sirepo.sim_data._flash_problem_files_archive_basename
        n=problemFiles-archive.${x[0]}.zip
        zip --quiet "$p/$n" *F90 Config Makefile
        r+=($n)
        cd ../..
    done
    cd ..
    r+=( "$(flash_tarball_patch_and_update_tgz "$t")" )
    x=$d/flash-$(date -u +%Y%m%d.%H%M%S).tar.gz
    rm -f "$x"
    tar czf "$x" "${r[@]}"
    ln -s --force "$(basename "$x")" $d/flash-dev.tar.gz
}

flash_tarball_patch_and_update_tgz() {
    declare src_tgz=$1
    declare b=FLASH$_flash_tarball_version
    tar xzf "$src_tgz"
    cd "$b"
    # POSIT: Fedora using mpich
    declare d=/usr/lib64/mpich
    patch --quiet sites/Prototypes/Linux/Makefile.h <<EOF
6c6
< MPI_PATH   = /usr/local/mpich2/
---
> MPI_PATH   = $d/
8,9c8,9
< HDF5_PATH  = /usr/local/hdf5
< HYPRE_PATH = /usr/local/hypre
---
> HDF5_PATH  = $d
> HYPRE_PATH = /home/vagrant/.local
70c70
< F90FLAGS =
---
> F90FLAGS = -fallow-argument-mismatch
EOF

    patch --quiet tools/python/flmake/setup.py <<'EOF'
@@ -32,7 +32,7 @@
     global RUNTIME_FILES

     # this is not a threaded application
-    sys.setcheckinterval(10000)
+    sys.setswitchinterval(10000)
     cwdir = os.getcwd()

     # setup.py is FLASH_HOME/bin/setup.py
EOF
    cd ..
    mv "$b" "flash"
    # POSIT: Matches sirepo.sim_data.flash._flash_src_tarball_basename
    declare r=flash.tar.gz
    tar czf "$r" flash
    echo "$r"
}

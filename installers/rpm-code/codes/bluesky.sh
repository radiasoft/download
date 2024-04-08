#!/bin/bash

bluesky_main() {
    codes_yum_dependencies mesa-libGL mongodb-org-server
    codes_dependencies common ipykernel shadow3 srw xraylib
    bluesky_mongo
    if install_version_fedora_lt_36; then
        install_pip_install git+https://github.com/NSLS-II/sirepo-bluesky.git@e8043a3a182e250fa1f429882bf2728f46d1ec3a
    else
        install_pip_install git+https://github.com/NSLS-II/sirepo-bluesky.git
    fi
    # https://github.com/radiasoft/container-beamsim-jupyter/issues/42#issuecomment-864152624
    # Install sirepo-bluesky from src because sirepo-bluesky on pypi is out of date (no ShadowFileHandler).
    # pychx depends on historydict but doesn't list it in install_requires.
    install_pip_install \
        ModestImage \
        PyQt5 \
        area_detector_handlers \
        bluesky-queueserver-api \
        dask \
        databroker-pack \
        git+https://github.com/NSLS-II-CSX/csxtools.git@52ff964439005c8340e71d77d2a73b22a71dba05 \
        git+https://github.com/NSLS-II/eiger-io.git \
        hdf5plugin \
        historydict \
        numcodecs \
        papermill \
        photutils \
        pyCHX==4.0.10 \
        pyOlog \
        scikit-beam \
        xray-vision \
        zarr

    bluesky_patch
}

bluesky_mongo() {
    local d=${codes_dir[share]}/intake
    local c=rsbluesky
    local r=/var/tmp/mongodb-rsbluesky
    local s=$r/mongod.sock
    local x=$(perl -MURI::Escape -e "print('mongodb://' . uri_escape('$s') . '/$c')")
    install -d -m 755 "$d"
    install -m 444 /dev/stdin "$d/$c.yml" <<EOF
sources:
  "$c":
    driver: bluesky-mongo-normalized-catalog
    args:
      metadatastore_db: "$x"
      asset_registry_db: "$x"
EOF
    codes_download_module_file "$c.sh"
    RSBLUESKY_ROOT_D=$r RSBLUESKY_SOCKET=$s RSBLUESKY_CATALOG=$c \
    perl -p -e 's/\$\{(\w+)\}/$ENV{$1} || die("$1: not found")/eg' "$c.sh" \
        | install -m 555 /dev/stdin "${codes_dir[bin]}"/"$c"
}

bluesky_patch() {
    local i
    for i in 'eiger_io fs_handler' 'modest_image modest_image' 'pyCHX chx_crosscor'; do
        set -- $i
        bluesky_patch_$1 | patch --quiet "$(codes_python_lib_dir)/$1/$2.py"
    done
}

bluesky_patch_eiger_io() {
    # Replace `f[v].value` with `f[v][()]`
    cat <<'EOF'
@@ -0,0 +1,2 @@
+#Modified to replace `f[v].value` with `f[v][()]`
+
@@ -4 +5,0 @@
-from glob import glob
@@ -48,3 +49,8 @@
-        valid_keys = [key for key in self._entry.keys() if
-                      key.startswith("data")]
-        valid_keys.sort()
+        valid_keys = []
+        for key in sorted(self._entry.keys()):
+            try:
+                self._entry[key]
+            except KeyError:
+                pass  # This is a link that leads nowhere.
+            else:
+                valid_keys.append(key)
@@ -138 +144 @@
-    def __call__(self, seq_id, frame_num=None):
+    def __call__(self, seq_id):
@@ -147,5 +152,0 @@
-            frame_num: int or None
-                If not None, return the frame_num'th image from this
-                3D array. Useful for when an event is one image rather
-                than a stack.
-
@@ -158 +159,2 @@
-            md = {k: f[v].value for k, v in self.EIGER_MD_LAYOUT.items()}
+            #MODIFIED
+            md = {k: f[v][()] for k, v in self.EIGER_MD_LAYOUT.items()}
@@ -173,4 +175 @@
-        ret = EigerImages(master_path, self._images_per_file, md=md)
-        if frame_num is not None:
-            ret = ret[frame_num]
-        return ret
+        return EigerImages(master_path, self._images_per_file, md=md)
@@ -178 +177 @@
-    def get_file_list(self, datum_kwargs_gen):
+    def get_file_list(self, datum_kwargs):
@@ -184 +183 @@
-        for dm_kw in datum_kwargs_gen:
+        for dm_kw in datum_kwargs:
@@ -186,2 +185,2 @@
-            new_filenames = glob(self._base_path + "_" + str(seq_id) + "*")
-            filenames.extend(new_filenames)
+            filename = '{}_{}_master.h5'.format(self._base_path, seq_id)
+            filenames.append(filename)
@@ -190,12 +188,0 @@
-
-    def get_file_sizes(self, datum_kwargs_gen):
-        '''get the file size
-
-           returns size in bytes
-        '''
-        sizes = []
-        file_name = self.get_file_list(datum_kwargs_gen)
-        for file in file_name:
-            sizes.append(os.path.getsize(file))
-
-        return sizes
EOF
}

bluesky_patch_modest_image() {
    # Matplotlib > 3 doesn't have _hold.
    # Can be removed when this is merged
    # https://github.com/ChrisBeaumont/mpl-modest-image/pull/12
    cat <<'EOF'
@@ -213,2 +212,0 @@
-    if not axes._hold:
-        axes.cla()
EOF
}

bluesky_patch_pyCHX() {
    # Fixes scipy version conflicts
    cat <<'EOF'
@@ -322,8 +322,6 @@

 #from . import sigtools
 import numpy as np
-from scipy._lib.six import callable
-from scipy._lib._version import NumpyVersion
 from scipy import linalg
 from scipy.fftpack import (fft, ifft, ifftshift, fft2, ifft2, fftn,
                            ifftn, fftfreq)
@@ -337,8 +335,6 @@
                    zeros_like)
 #from ._arraytools import axis_slice, axis_reverse, odd_ext, even_ext, const_ext

-_rfft_mt_safe = (NumpyVersion(np.__version__) >= '1.9.0.dev-e24486e')
-
 _rfft_lock = threading.Lock()

 def fftconvolve_new(in1, in2, mode="full"):
EOF
}

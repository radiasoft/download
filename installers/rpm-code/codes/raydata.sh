#!/bin/bash

raydata_main() {
    codes_dependencies common
    install_pip_install \
        ModestImage \
        area_detector_handlers \
        databroker-pack \
        git+https://github.com/NSLS-II/eiger-io.git \
        hdf5plugin \
        pyOlog \
        pychx \
        xray-vision

    raydata_patch
}

raydata_patch() {
    local p=$(python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')
    for i in 'eiger_io fs_handler' 'modest_image modest_image' 'pyCHX chx_crosscor' 'xray_vision  __init__'; do
        set -- $i
        raydata_patch_$1 | patch --quiet "$p/$1/$2.py"
    done
}

raydata_patch_eiger_io() {
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

raydata_patch_modest_image() {
    # Matplotlib > 3 doesn't have _hold.
    # Can be removed when this is merged
    # https://github.com/ChrisBeaumont/mpl-modest-image/pull/12
    cat <<'EOF'
@@ -213,2 +212,0 @@
-    if not axes._hold:
-        axes.cla()
EOF
}

raydata_patch_pyCHX() {
    # Fixes scipy version conflicts
    cat <<'EOF'
@@ -0,0 +1 @@
+#Further modified to remove scipy conflicts with Py3
@@ -319 +319,0 @@
-
@@ -325 +325,3 @@
-from numpy.lib import NumpyVersion
+from six import callable
+#from scipy._lib.six import callable
+#from scipy._lib._version import NumpyVersion
@@ -339 +341 @@
-_rfft_mt_safe = (NumpyVersion(np.__version__) >= '1.9.0.dev-e24486e')
+#_rfft_mt_safe = (NumpyVersion(np.__version__) >= '1.9.0.dev-e24486e')
EOF
}

raydata_patch_xray_vision() {
    # sip is now included in PyQt5
    # https://www.riverbankcomputing.com/static/Docs/PyQt5/incompatibilities.html#pyqt-v5-11
    cat <<'EOF'
@@ -35,0 +36 @@
+# #Modified to replace import sip with PyQt5 sip version
@@ -37 +37,0 @@
-import sip
@@ -42,0 +43 @@
+from PyQt5 import sip
EOF
}

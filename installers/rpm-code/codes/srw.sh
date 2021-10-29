#!/bin/bash

srw_main() {
    codes_yum_dependencies fftw2-devel
    codes_dependencies bnlcrl ml
    codes_download ochubar/SRW
    # committed *.so files are not so good.
    find . -name \*.so -o -name \*.a -o -name \*.pyd -exec rm {} \;
    perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
    perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
    cd cpp/gcc
    codes_make lib
}

srw_python_install() {
    install_pip_install primme
    cd SRW/cpp/py
    make python
    cd ../..
    srw_python_patch_srwlib
    codes_python_lib_copy env/work/srw_python/{{srwl,uti}*.py,srwlpy*.so}
    find . -name srwlpy\*.so -exec rm {} \;
}

srw_python_patch_srwlib() {
    patch --quiet env/work/srw_python/srwlib.py <<'EOF'
diff --git a/env/work/srw_python/srwlib.py b/env/work/srw_python/srwlib.py
index 9e052df..0ab17fb 100644
--- a/env/work/srw_python/srwlib.py
+++ b/env/work/srw_python/srwlib.py
@@ -10267,6 +10267,8 @@ def srwl_wfr_emit_prop_multi_e(_e_beam, _mag, _mesh, _sr_meth, _sr_rel_prec, _n_
                         #srwl_uti_save_intens_ascii(resStokes2.to_deg_coh(), meshRes2, fpdc2, _n_stokes = 1, _arLabels = resLabelsToSaveDC, _arUnits = resUnitsToSaveDC, _mutual = doMutual, _cmplx = 0) #OC12072019 # Deg. of Coh. Cut vs Y
                         #srwl_uti_save_intens_ascii(resStokes2.to_deg_coh(), meshRes2, fpdc2, _n_stokes = 1, _arLabels = resLabelsToSaveDC, _arUnits = resUnitsToSaveDC, _mutual = 2, _cmplx = 0) #OC16072019 # Deg. of Coh. Cut vs Y
                         srwl_uti_save_intens(resStokes2.to_deg_coh(), meshRes2, fpdc2, _n_stokes = 1, _arLabels = resLabelsToSaveDC, _arUnits = resUnitsToSaveDC, _mutual = 2, _cmplx = 0, _form = _file_form) #OC17072021 # Deg. of Coh. Cut vs Y
+                elif _char == 61:
+                    pass
                 else:
                     #srwl_uti_save_intens_ascii(resStokes.arS, meshRes, file_path1, numComp, _arLabels = resLabelsToSave, _arUnits = resUnitsToSave, _mutual = doMutual, _cmplx = (1 if doMutual else 0)) #OC30052017
                     #srwl_uti_save_intens_ascii(resStokes.arS, meshRes, fp1, numComp, _arLabels = resLabelsToSave, _arUnits = resUnitsToSave, _mutual = doMutual, _cmplx = (1 if doMutual else 0)) #OC14082018
EOF
}

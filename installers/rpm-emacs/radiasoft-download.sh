rpm_emacs_cm_patch() {
    patch --quiet src/cm.c <<'EOF'
diff --git src/cm.c src/cm.c
index a175b4a..3fb7ff3 100644
--- a/src/cm.c
+++ b/src/cm.c
@@ -370,0 +371,11 @@ cmgoto (struct tty_display_info *tty, int row, int col)
+  /* https://github.com/martintrojer/emacs/commit/bdff1ff98d02f4307659c052d0b35a40a36f0706 */
+  /* only use direct moves */
+  cost = 0;
+  p = (dcm == tty->Wcm->cm_habs
+       ? tgoto (dcm, row, col)
+       : tgoto (dcm, col, row));
+  emacs_tputs (tty, p, 1, evalcost);
+  emacs_tputs (tty, p, 1, cmputc);
+  curY (tty) = row, curX (tty) = col;
+  return;
+
EOF
}

rpm_emacs_centos_yum() {
    install_yum_install centos-release-scl
    install_yum_install \
        GConf2-devel \
        Xaw3d-devel \
        devtoolset-11-gcc \
        devtoolset-11-libgccjit-devel \
        dbus-devel \
        dbus-glib-devel \
        dbus-python \
        gcc \
        giflib-devel \
        gnutls-devel \
        gpm-devel \
        gtk+-devel \
        gtk2-devel \
        ImageMagick \
        ImageMagick-devel \
        jansson-devel \
        lcms2-devel \
        libX11-devel \
        libXft-devel \
        libXpm-devel \
        libjpeg-devel \
        libpng-devel \
        libotf-devel \
        librsvg2-devel \
        libtiff-devel \
        libungif-devel \
        make \
        ncurses-devel \
        pkgconfig \
        texi2html \
        texinfo
}
rpm_emacs_main() {
}

rpm_emacs_make() {
    git clone https://git.savannah.gnu.org/git/emacs.git
    cd emacs
    git checkout emacs-28.2
    source /opt/rh/devtoolset-11/enable
    ./autogen.sh
    PKG_CONFIG_PATH=/usr/lib64/pkgconfig ./configure --with-native-compilation
    make -j$(install_num_cores) NATIVE_FULL_AOT=1
    make install
    install -m 444 /dev/stdin /etc/ld.so.conf.d/emacs-28.2-x86_64.conf <<EOF
/opt/rh/devtoolset-11/root/usr/lib64
EOF
    find the files in /usr/local that are new
}

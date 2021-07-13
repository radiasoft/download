#!/bin/bash

bluesky_hdf5() {
    codes_download nexusformat/HDF5-External-Filter-Plugins
    codes_cmake -DENABLE_LZ4_PLUGIN=yes
    codes_make
    install -m 555 plugins/libh5lz4.so "${codes_dir[lib]}"
}

bluesky_main() {
    codes_yum_dependencies lz4-devel mongodb-org-server
    codes_dependencies common
    bluesky_mongo
    # https://github.com/radiasoft/container-beamsim-jupyter/issues/42#issuecomment-864152624
    # install from src because sirepo-bluesky on pypi is out of date (no ShadowFileHandler)
    install_pip_install \
        git+https://github.com/NSLS-II/sirepo-bluesky.git \
        scikit-beam
    bluesky_hdf5
}

bluesky_mongo() {
    local d=${codes_dir[lib]}/intake
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

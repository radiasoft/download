#!/bin/bash

bluesky_main() {
    codes_yum_dependencies mongodb-org-server
    codes_dependencies common ipykernel shadow3 srw xraylib
    bluesky_mongo
    if install_version_fedora_lt_36; then
        install_pip_install git+https://github.com/NSLS-II/sirepo-bluesky.git@e8043a3a182e250fa1f429882bf2728f46d1ec3a
    else
        install_pip_install git+https://github.com/NSLS-II/sirepo-bluesky.git@66d6b2e3810749ede8f9d0380279fa5a43c79aaa
    fi
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

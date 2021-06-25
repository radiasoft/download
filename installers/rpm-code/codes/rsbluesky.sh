#!/bin/bash
set -euo pipefail

rsbluesky_main() {
    codes_yum_dependencies lz4-devel
    codes_dependencies common
    # https://github.com/radiasoft/container-beamsim-jupyter/issues/42#issuecomment-864152624
    # install from src because sirepo-bluesky on pypi is out of date (no ShadowFileHandler)
    install_pip_install git+https://github.com/NSLS-II/sirepo-bluesky.git \
                        scikit-beam
    rsbluesky_hdf5
    rsbluesky_mongo
}

rsbluesky_hdf5() {
    codes_download nexusformat/HDF5-External-Filter-Plugins
    codes_cmake -DENABLE_LZ4_PLUGIN=yes -DCMAKE_INSTALL_PREFIX=$PWD
    codes_make_install
    local f=libh5lz4.so
    install -m 555 ./plugins/$f "${codes_dir[lib]}"/$f
}

rsbluesky_mongo() {
    # TODO(e-carlin):  all of the mongo paths below are messed up; talk with rn
    install -m 555 /dev/stdin "${codes_dir[bin]}"/rsbluesky <<EOF
#!/bin/bash
set -euo pipefail

databroker_catalog="rsbluesky"
intake_d=${codes_dir[share]}/intake
mongo_d=/var/tmp/mongodb
mongo_db_d=\$mongo_d/db
mongo_conf_f=\$mongo_d/mongo.conf
mongo_log_f=\$mongo_d/mongo.log
# Does not bind to this port. Just used in socket filename.
mongo_port=8080
mongo_sock_f=\$mongo_d/mongodb-\$mongo_port.sock
mongo_sock_f_encoded="\$(perl -MURI::Escape -e 'print uri_escape(\$ARGV[0]);' \$mongo_sock_f)"

mkdir -p \$mongo_db_d
mkdir -p \$intake_d

cat > \$intake_d/\$databroker_catalog.yml <<RSBLUESKY_CONF
sources:
  \$databroker_catalog:
    driver: bluesky-mongo-normalized-catalog
    args:
      metadatastore_db: mongodb://\$mongo_sock_f_encoded/rsbluesky
      asset_registry_db: mongodb://\$mongo_sock_f_encoded/rsbluesky
RSBLUESKY_CONF

cat > \$mongo_conf_f <<MONGO_CONF
systemLog:
  destination: file
  logAppend: true
  path: \$mongo_log_f
storage:
  # dbPath: /var/lib/mongo
  dbPath: \$mongo_db_d
  journal:
    enabled: true
processManagement:
  fork: true
  pidFilePath: \$mongo_d/mongodb.pid
  timeZoneInfo: /usr/share/zoneinfo
net:
  port: \$mongo_port
  bindIp: \$mongo_sock_f
  unixDomainSocket:
    pathPrefix: \$mongo_d
MONGO_CONF

if ! mongod --config \$mongo_conf_f; then
  echo There was a problem starting mongo. Please see \$mongo_log_f for more info.
  tail -n 25 \$mongo_log_f
  exit 1
fi
echo Use databroker catalog \$databroker_catalog
EOF
}

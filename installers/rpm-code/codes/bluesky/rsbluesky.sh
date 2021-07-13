#!/bin/bash
set -euo pipefail
db_d=${1:-}
if [[ ! $db_d ]]; then
    echo "usage: $0 mongo-db-directory
You must supply a mongo-db-directory directory" 1>&2
    exit 1
fi
if [[ ! $db_d =~ ^/ ]]; then
    db_d=$PWD/$db_d
fi
root_d=${RSBLUESKY_ROOT_D}
if [[ -e $root_d ]]; then
    if pgrep -f "mongod --config $root_d"; then
        echo "mongod is already running" 1>&2
        exit 1
    fi
    echo "$root_d exists, but mongod is not running. Run:

    rm -rf $root_d

Then try this command again." 1>&2
    exit 1
fi
conf_f=$root_d/mongod.conf
log_f=$root_d/mongod.log
(umask 077; mkdir -p "$db_d" "$root_d")
install -m 400 /dev/stdin "$conf_f" <<EOF
systemLog:
  destination: file
  logAppend: true
  path: "$log_f"
storage:
  dbPath: "$db_d"
  journal:
    enabled: true
processManagement:
  fork: true
  pidFilePath: "$root_d/mongod.pid"
  timeZoneInfo: /usr/share/zoneinfo
net:
  # this port is not used, but must be there
  port: 1
  bindIp: "${RSBLUESKY_SOCKET}"
  unixDomainSocket:
    enabled: true
    filePermissions: 0700
    pathPrefix: "$root_d"
EOF
if ! mongod --config "$conf_f"; then
  echo "There was a problem starting mongo. Please see $log_f for more info." 1>&2
  tail -n 25 "$log_f" 1>&2
  exit 1
fi
echo "mongdb started
Use databroker catalog '${RSBLUESKY_CATALOG}'"

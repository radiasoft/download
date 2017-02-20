#!/bin/bash
#
# This tests the installed (curl radia.run) version, since that goes live
# as soon as we checkin.
#
set -e -o pipefail
trap 'echo FAILED' ERR EXIT
sentinel=test-$RANDOM-sentinel
out=$(docker run --rm -it radiasoft/python2 su - vagrant 2>&1 <<EOF)
set -e -o pipefail
curl radia.run | bash -s code test
echo "$sentinel"
EOF
if [[ ! $out =~ PASSED ]]; then
    echo "curl radia.run didn't output PASSED: $out" 1>&2
    exit 1
fi
if [[ ! $out =~ $sentinel ]]; then
    echo "failed to find $sentinel: $out" 1>&2
    exit 1
fi
trap - EXIT
echo PASSED

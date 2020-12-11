#!/bin/bash
#
# This tests the installed (curl radia.run) version, since that goes live
# as soon as we checkin.
#
set -e -o pipefail
trap 'echo FAILED' ERR EXIT
sentinel=test-$RANDOM-sentinel
echo '

This test is broken

'
exit 1
need to figure out how to have "test" available.
out=$(docker run --rm -i fedora:32 2>&1 <<EOF || true
set -e -o pipefail
curl https://depot.radiasoft.org/index.sh | bash -s debug code test
echo "$sentinel"
EOF
)
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

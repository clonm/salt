#!/bin/bash

# A hack to fix unexplainable debsums mismatches on few packages.
#
# See: https://serverfault.com/questions/855062/how-to-get-rid-of-debsums-reporting-mismatches-for-core-packages
#      https://bugs.launchpad.net/ubuntu/+source/module-init-tools/+bug/1681126
#      https://bugs.launchpad.net/ubuntu/+bug/1681129
#
# It just reinstalls offending packages before debsums runs every day.

export DEBIAN_FRONTEND='noninteractive'

PACKAGES=(libkmod2)
OUTPUT='/tmp/debsums-fix-output'

function cleanup {
  rm -f "$OUTPUT"
}
trap cleanup EXIT

for package in ${PACKAGES[@]}; do
  if dpkg-query -W --showformat='${Status}\n' "$package" 2>&1 | grep -q 'install ok installed' ; then
    rm -f "$OUTPUT"
    apt-get --yes --quiet install --reinstall "$package" > "$OUTPUT" 2>&1
    EXIT_STATUS=$?
    if [ $EXIT_STATUS -ne 0 ]; then
      cat "$OUTPUT"
      rm -f "$OUTPUT"
      exit $EXIT_STATUS
    fi
  fi
done

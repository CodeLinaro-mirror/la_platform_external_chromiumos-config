#!/bin/bash
HASH_TAG=$1
COMMAND=$2
GERRIT_ARG=$3

if [[ -z "${HASH_TAG}" ]]; then
  echo "CL hashtag required to search CLs"
  exit 1
fi

if [[ -z "${COMMAND}" ]]; then
  echo "gerrit command to run required"
  exit 1
fi

for cl in $(../../../../chromite/bin/gerrit -i \
  --raw search "status:open hashtag:${HASH_TAG}"); do
  ../../../../chromite/bin/gerrit -i "${2}" "${cl}" ${3}
done


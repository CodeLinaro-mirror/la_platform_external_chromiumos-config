#!/bin/bash
HASH_TAG=$1

if [[ -z "${HASH_TAG}" ]]; then
  echo "CL hashtag required to search CLs"
  exit 1
fi

../../../../chromite/bin/gerrit -i --raw search "owner:me status:open hashtag:${HASH_TAG}" \
  | xargs echo | sed 's/ /, /g'

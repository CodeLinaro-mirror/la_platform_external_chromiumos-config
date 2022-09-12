#!/bin/bash
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs the script once per program repo where projects are managed under the
# program repo else once per project repo.

SCRIPT=$1

if [[ -z "${SCRIPT}" ]]; then
  echo "Script to run is required."
  exit 1
fi

cd ../../program
for program in *; do
  cd "${program}"
  projects=$(ls **/generated)

  if [[ -n "${projects}" ]]; then
    echo "Running ${SCRIPT} for ${program}"
    ../../config/scripts/${SCRIPT} ${program}
  fi

  if [[ -d "../../project/${program}" ]]; then
    cd "../../project/${program}"
    for project in *; do
      if [[ -d "${project}/generated" ]]; then
        cd "${project}"
        echo "Running ${SCRIPT} for ${project}"
        ../../../config/scripts/${SCRIPT} ${project}
        cd ..
      fi
    done
    cd "../../program/${program}"
  fi

  cd ..
done

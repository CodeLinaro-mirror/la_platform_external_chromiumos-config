#!/bin/bash
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Iterates over all projects in program or project repos and runs a supplied
# refactoring script for each project.
SCRIPT=$1

if [[ -z "${SCRIPT}" ]]; then
  echo "Script to run is required."
  exit 1
fi

cd ../../program
for program in *; do
  cd "${program}"

  for project in *; do
    if [[ -d "${project}/generated" ]]; then
      cd "${project}"
      echo "Running ${SCRIPT} for ${project}"
      ../../../config/scripts/${SCRIPT} ${project}
      cd ..
    fi
  done

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

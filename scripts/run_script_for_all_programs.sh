#!/bin/bash
# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Iterates over all programs and runs the specified script.
SCRIPT=$1

if [[ -z "${SCRIPT}" ]]; then
  echo "Script to run is required."
  exit 1
fi

cd ../../program
for program in *; do
  cd "${program}"
  echo "Running ${SCRIPT} for ${program}"
  ../../config/scripts/${SCRIPT} ${program}
  cd ..
done

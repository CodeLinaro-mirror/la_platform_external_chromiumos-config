#!/bin/bash
# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

find_checkout_root() {
  path="$(dirname "$0")"
  path="$(realpath "${path}")"
  while [[ "${path}" != "/" && ! -d "${path}/.repo" ]]
  do
    path="$(dirname "${path}")"
  done
  echo "${path}"
}

# Setup a project.
mkdir -p /tmp/setup_project || exit $?
cipd install -force -root /tmp/setup_project \
  chromiumos/infra/setup_project/\$\{platform\} latest || exit $?
echo "Done installing CIPD package."

# If --checkout is not supplied, assume that this script is being run from
# a checkout. Find the root of the checkout.
if [[ "$*" != *"-checkout"* ]]; then
  echo "--checkout not supplied, searching for checkout root."
  checkout_root="$(find_checkout_root)"
  echo "Found checkout root ${checkout_root}."
  if [[ "${checkout_root}" != "/" ]]; then
    set -- "$@" "-checkout=$(find_checkout_root)/"
  else
    echo "You are invoking setup_project.sh from outside of a CrOS checkout."
    echo "Please specify the location of the checkout with -checkout."
  fi
fi
/tmp/setup_project/setup_project setup-project "$@"

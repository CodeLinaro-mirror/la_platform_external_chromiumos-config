# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Defines ConstraintSuite, which is subclassed to define constraints."""

import inspect

from bindings.src.config.proto.api import config_bundle_pb2


class InvalidConstraintSuiteError(Exception):
  """Exception raised when an invalid ConstraintSuite is defined."""


class ConstraintSuite:
  """A class whose instances are suites of constraints.

  Constraint authors should subclass ConstraintSuite and add methods starting
  with "check" for each constraint they want to enforce. Each check method
  should accept two ConfigBundles, with parameter names "project_config" and
  "program_config". A check method is considered failed iff it raises an
  Exception.

  A ConstraintSuite subclass should group related constraints. For example a
  suite to check form factor constraints could look like:

  class FormFactorConstraintSuite(ConstraintSuite):

    def checkFormFactorDefined(self, program_config, project_config):
      ...

    def checkFormFactorAllowedByProgram(self, program_config, project_config):
      ...

  A ConstraintSuite that defines no check methods will raise an exception on
  initialization.
  """

  def __init__(self):
    super().__init__()

    def is_check(name, value):
      return name.startswith('check') and inspect.ismethod(value)

    self._checks = [
        value for name, value in inspect.getmembers(self)
        if is_check(name, value)
    ]

    if not self._checks:
      raise InvalidConstraintSuiteError('No checks found on %s' % type(self))

  def run_checks(self,
                 program_config: config_bundle_pb2.ConfigBundle,
                 project_config: config_bundle_pb2.ConfigBundle,
                 verbose: int = 0):
    """Runs all of the checks on an instance.

    Args:
      program_config: The program's config, to pass to each check.
      project_config: The project's config, to pass to each check.
      verbose: Verbosity mode, 0: silent, >= 1: print name of check.
    """
    for method in self._checks:
      if verbose:
        # TODO(crbug.com/1051187): Improve logging and failure reporting.
        print('Running {}.{}'.format(self.__class__.__name__, method.__name__))
      method(program_config=program_config, project_config=project_config)

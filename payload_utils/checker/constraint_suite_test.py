# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Tests for constraint_suite."""

import os
import pathlib
import tempfile
import unittest

from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle
from chromiumos.config.api.design_pb2 import DesignList, Design
from chromiumos.config.api.program_pb2 import ProgramList, Program

from checker.constraint_suite import (ConstraintSuite,
                                      InvalidConstraintSuiteError)


class ValidConstraintSuite(ConstraintSuite):
  """A valid constraint suite, that defines two checks."""

  def _helper_method(self):
    assert False, "helper_method should never be called"

  def check_program_valid(
      self,
      program_config,
      project_config,
      factory_dir,
  ):
    del project_config, factory_dir
    self.assertEqual(program_config.programs.value[0].name, 'TestProgram1')

  def check_project_valid(
      self,
      program_config,
      project_config,
      factory_dir,
  ):
    del program_config, factory_dir
    self.assertEqual(project_config.designs.value[0].name, 'TestDesign1')


class FactoryDirSuite(ConstraintSuite):
  """A valid constraint suite that expects a file in factory_dir."""

  def check_generated_config_present(
      self,
      program_config,
      project_config,
      factory_dir,
  ):
    del program_config, project_config
    self.assertTrue(os.path.exists(os.path.join(factory_dir, 'test.txt')))


class InvalidConstraintSuite(ConstraintSuite):
  """An invalid constraint suite, that defines no checks."""

  def helper_method1(self):
    pass

  def helper_method2(self):
    pass


class ConstraintSuiteTest(unittest.TestCase):

  def test_runs_checks(self):
    """Tests running checks on a project that fulfills constraints."""
    program_config = ConfigBundle(
        programs=ProgramList(value=[Program(name='TestProgram1')]))
    project_config = ConfigBundle(
        designs=DesignList(value=[Design(name='TestDesign1')]))

    ValidConstraintSuite().run_checks(
        program_config=program_config,
        project_config=project_config,
        factory_dir=None)

  def test_runs_checks_fails_constraint(self):
    """Tests running checks on a project that violates constraints."""
    program_config = ConfigBundle(
        programs=ProgramList(value=[Program(name='TestProgram2')]))
    project_config = ConfigBundle(
        designs=DesignList(value=[Design(name='TestDesign1')]))

    with self.assertRaisesRegex(AssertionError,
                                "'TestProgram2' != 'TestProgram1'"):
      ValidConstraintSuite().run_checks(
          program_config=program_config,
          project_config=project_config,
          factory_dir=None)

  def test_checks_factory_dir(self):
    """Tests running checks that a file in factory_dir is present."""

    with tempfile.TemporaryDirectory() as tmpdir:
      with open(os.path.join(tmpdir, 'test.txt'), 'w') as fp:
        fp.write('test file\n')

      FactoryDirSuite().run_checks(
          program_config=None,
          project_config=None,
          factory_dir=pathlib.Path(tmpdir),
      )

  def test_checks_factory_dir_violated(self):
    """Tests running checks that fail because a file in factory_dir is
    not present.
    """

    with tempfile.TemporaryDirectory() as tmpdir:
      with self.assertRaises(AssertionError):
        FactoryDirSuite().run_checks(
            program_config=None,
            project_config=None,
            factory_dir=pathlib.Path(tmpdir),
        )

  def test_runs_checks_invalid_suite(self):
    """Tests creating a ConstraintSuite with no checks."""
    with self.assertRaisesRegex(InvalidConstraintSuiteError,
                                'No checks found on.*InvalidConstraintSuite'):
      InvalidConstraintSuite()

  def test_has_delegated_assertions(self):
    """Tests that ConstraintSuites have assertion methods."""
    constraint_suite = ValidConstraintSuite()
    self.assertTrue(hasattr(constraint_suite, 'assertTrue'))
    with self.assertRaisesRegex(AssertionError, "1 != 2"):
      constraint_suite.assertEqual(1, 2)

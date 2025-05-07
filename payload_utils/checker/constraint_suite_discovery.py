# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Module to dynamically discover and load ConstraintSuites"""

import contextlib
import glob
import importlib
import inspect
import os
import sys
from typing import List

# Disable spurious no-name-in-module and import-error lints.
# pylint: disable=no-name-in-module, import-error
from checker import constraint_suite


@contextlib.contextmanager
def _prepend_to_pythonpath(directory: str):
    """Yields a context with directory prepended to sys.path.

    Directory is removed from sys.path when the context is exited. This can be
    used when a directory temporarily needs to be prepended to sys.path, without
    polluting sys.path permanently. For example:

    with _prepend_to_pythonpath(some_dir):
      importlib.import_module(some_mod)
    """
    sys.path.insert(0, directory)
    yield
    sys.path.remove(directory)


def discover_suites(
    directory: str,
    pattern: str = "check*.py",
    exclude_pattern: str = "*test.py",
) -> List[constraint_suite.ConstraintSuite]:
    """Returns instances of all ConstraintSuites defined in a directory.

    All files matching pattern in directory are dynamically loaded (pattern must
    specify Python files). If those modules define a subclass of ConstraintSuite
    an instance of this of this subclass is returned in the list of
    ConstraintSuites.

    Args:
        directory: Directory to search. Note that the search is not recursive.
        pattern: Filename pattern to match. Must be compatible with the glob
            module. Must specify Python files.
        exclude_pattern: Filename pattern to exclude. Must be compatible with
            the glob module. If a file matches both pattern and exclude_pattern,
            it will be excluded.
    """
    if not pattern.endswith(".py"):
        raise ValueError('pattern must end with ".py"')

    # Sort discovered modules, so suites can be run in this order.
    module_files = sorted(
        set(glob.glob(os.path.join(directory, pattern)))
        - set(glob.glob(os.path.join(directory, exclude_pattern)))
    )

    # Convert file names -> module names. This means strip the '.py' and get
    # only the filename (directory will be added to path so the modules can be
    # loaded).
    module_names = []
    for f in module_files:
        assert f.endswith(".py")
        module_names.append(os.path.basename(f)[:-3])

    # Create a context with directory in path, so modules can be loaded.
    with _prepend_to_pythonpath(directory):
        suites = []
        for name in module_names:
            module = importlib.import_module(name)

            # Inspect all classes defined in the module. If a class is a
            # subclass of ConstraintSuite, add an instance of the class to
            # suites.
            for _, cls in inspect.getmembers(module, predicate=inspect.isclass):
                if issubclass(cls, constraint_suite.ConstraintSuite):
                    suites.append(cls())

    # pytype has trouble inferring the type when the return statement is nested
    # within the with block. Thus, pull the return statement outside the with
    # block, which should be equivalent behavior.
    return suites

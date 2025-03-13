# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Abstract base class for Merge plugins"""

from abc import ABC, abstractmethod

from chromiumos.config.payload.config_bundle_pb2 import ConfigBundle


class MergePlugin(ABC):
    """Abstract base class for Merge plugins"""

    @abstractmethod
    def merge(self, bundle: ConfigBundle):
        """Merge into the given ConfigBundle instance."""

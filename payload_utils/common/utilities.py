#!/usr/bin/env python3
# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""General-purpose utility functions that don't belong elsewhere."""


def levenshtein_distance(aa: str, bb: str) -> int:
    """Compute the Levenshtein distance between two strings.

    This is the minimum number of single-character edits required to change aa
    into bb and serves usefully as a distance metric between strings.

    Args:
        aa: first string
        bb: second string

    Returns:
        Edit distance between aa and bb.
    """

    # pylint: disable=invalid-name

    # We're effectively building a matrix of distances between two prefixes
    # of the strings:
    #
    #     0 1 2 3
    #    │ │c│a│t│
    #   ─┼─┼─┼─┼─┼
    # 0 s│1│1│2│3│
    #   ─┼─┼─┼─┼─┼
    # 1 a│2│2│1│2│
    #   ─┼─┼─┼─┼─┼
    # 2 d│3│3│2│2│
    #
    # But, if we don't want the _actual_ edit sequence, we can just keep the
    # first two rows.

    # if bb is empty, edit distance is just deleting aa.
    if not bb:
        return len(aa)

    # similarly, if aa is empty, edit distance is just inserting bb.
    if not aa:
        return len(bb)

    prev_dist = list(range(len(bb) + 1))
    curr_dist = [0] * (len(bb) + 1)

    for ii, chara in enumerate(aa):
        # we can always remove ii+1 characters to match the empty string.
        curr_dist[0] = ii + 1

        # compute cost of each of three operations from previous
        # distances and choose the cheapest one.
        for jj, charb in enumerate(bb):
            cost_delete = prev_dist[jj + 1] + 1
            cost_insert = curr_dist[jj] + 1
            cost_change = prev_dist[jj]
            if chara != charb:
                cost_change += 1

            curr_dist[jj + 1] = min(cost_delete, cost_insert, cost_change)

        # swap
        curr_dist, prev_dist = prev_dist, curr_dist

    return prev_dist[-1]

#!/usr/bin/env python3
"""
Job 4 — Popular Entity by Country : REDUCER
===========================================
Input  (sorted): <TAG>|<country> \\t <entity_value>\\t<total_requests>
Output:          POP_<TAG>       \\t country,entity_value,total_requests

For every country the entity with the highest request count wins. Ties are
broken alphabetically on the entity name, so the pipeline is deterministic.

Example — from
    country,team,total_requests
    A,B,2
    A,Z,1
    B,Z,1
we produce
    country,popular_team,total_requests
    A,B,2
    B,Z,1
"""
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
# common.py lives next to us on the cluster (shipped with -files) and in
# the parent directory when running the local debug pipeline.
sys.path.insert(0, _HERE)
sys.path.insert(0, os.path.dirname(_HERE))
from common import group_by_key, read_lines, to_csv  # noqa: E402


def main():
    for key, values in group_by_key(read_lines()):
        if "|" not in key:
            continue
        tag, country = key.split("|", 1)

        best_entity = None
        best_count = -1
        for value in values:
            if "\t" not in value:
                continue
            entity, count_str = value.rsplit("\t", 1)
            try:
                count = int(count_str)
            except ValueError:
                continue
            if count > best_count or (count == best_count and entity < best_entity):
                best_entity = entity
                best_count = count

        if best_entity is None:
            continue

        sys.stdout.write("POP_%s\t%s\n" % (tag, to_csv([country, best_entity, best_count])))


if __name__ == "__main__":
    main()

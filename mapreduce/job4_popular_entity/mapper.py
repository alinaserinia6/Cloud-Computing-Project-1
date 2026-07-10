#!/usr/bin/env python3
"""
Job 4 — Popular Entity by Country : MAPPER
==========================================
Input : the raw Job 3 output on HDFS, i.e. lines of
            <TAG> \\t country,entity_value,total_requests

MapReduce logic:
    Mapper : country -> (entity_value, total_requests)
    Reducer: for each country pick the entity_value with the maximum count

We keep TAG inside the key so that teams, match days, stadiums and cities are
reduced independently in the very same job.

Emits:  <TAG>|<country> \\t <entity_value>\\t<total_requests>
"""
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
# common.py lives next to us on the cluster (shipped with -files) and in
# the parent directory when running the local debug pipeline.
sys.path.insert(0, _HERE)
sys.path.insert(0, os.path.dirname(_HERE))
from common import from_csv  # noqa: E402

VALID_TAGS = {"TEAM", "MATCHDAY", "STADIUM", "CITY"}


def main():
    for raw in sys.stdin:
        raw = raw.rstrip("\n").rstrip("\r")
        if not raw or "\t" not in raw:
            continue
        tag, row = raw.split("\t", 1)
        if tag not in VALID_TAGS:
            continue
        try:
            f = from_csv(row)
        except Exception:
            continue
        if len(f) < 3:
            continue

        country, entity_value, total = f[0], f[1], f[2]
        try:
            total = int(total)
        except ValueError:
            continue

        # value carries entity + count; the reducer splits on the last tab
        sys.stdout.write("%s|%s\t%s\t%d\n" % (tag, country, entity_value, total))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Job 1 — Parsing and Cleaning : REDUCER
======================================
Input  (sorted by key):  <dedupe_key> \\t <TAG> \\t <csv line>
Output:                  <TAG>        \\t <csv line>

The reducer's job is idempotency: every request_id must appear exactly once
in the cleaned output, even if a log file was accidentally ingested twice.
Because the dedupe key already carries the record family, TAG is simply the
first field of the value.

run_mapreduce.sh then splits the tagged stream into:
    outputs/job1/cleaned_nginx_logs.csv
    outputs/job1/cleaned_service_logs.csv
    outputs/job1/invalid_logs.csv
"""
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
# common.py lives next to us on the cluster (shipped with -files) and in
# the parent directory when running the local debug pipeline.
sys.path.insert(0, _HERE)
sys.path.insert(0, os.path.dirname(_HERE))
from common import group_by_key, read_lines  # noqa: E402


def main():
    for _key, values in group_by_key(read_lines()):
        # Keep the first record for this key, drop exact duplicates.
        sys.stdout.write(values[0] + "\n")


if __name__ == "__main__":
    main()

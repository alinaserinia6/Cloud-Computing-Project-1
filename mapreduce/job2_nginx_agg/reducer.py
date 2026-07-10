#!/usr/bin/env python3
"""
Job 2 — General Nginx Aggregation : REDUCER
===========================================
For each (family, name) key it computes:
    total_requests
    success_count      (status < 400)
    error_4xx          (400 <= status < 500)
    error_5xx          (status >= 500)
    error_rate         (error_4xx + error_5xx) / total_requests
    avg_response_time_ms

Output (tagged so run_mapreduce.sh can split it into three CSV files):
    SVC \\t service,total,success,4xx,5xx,error_rate,avg_ms
    EP  \\t endpoint,total,success,4xx,5xx,error_rate,avg_ms
    SCN \\t scenario,total,success,4xx,5xx,error_rate,avg_ms
"""
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
# common.py lives next to us on the cluster (shipped with -files) and in
# the parent directory when running the local debug pipeline.
sys.path.insert(0, _HERE)
sys.path.insert(0, os.path.dirname(_HERE))
from common import group_by_key, read_lines, to_csv  # noqa: E402

TAGS = {"SVC": "SVC", "EP": "EP", "SCN": "SCN"}


def main():
    for key, values in group_by_key(read_lines()):
        if "|" not in key:
            continue
        family, name = key.split("|", 1)
        if family not in TAGS:
            continue

        total = 0
        success = 0
        err4 = 0
        err5 = 0
        total_ms = 0

        for value in values:
            try:
                status_str, ms_str = value.split(",", 1)
                status = int(status_str)
                ms = int(ms_str)
            except ValueError:
                continue
            total += 1
            total_ms += ms
            if status >= 500:
                err5 += 1
            elif status >= 400:
                err4 += 1
            else:
                success += 1

        if total == 0:
            continue

        error_rate = round((err4 + err5) / float(total), 4)
        avg_ms = round(total_ms / float(total), 2)

        row = to_csv([name, total, success, err4, err5, error_rate, avg_ms])
        sys.stdout.write("%s\t%s\n" % (family, row))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Job 2 — General Nginx Aggregation : MAPPER
==========================================
Input : cleaned_nginx_logs.csv (headerless), i.e. the Job 1 Nginx output
        timestamp,request_id,client_country,scenario,service,method,path,
        status_code,request_time_ms,user_agent

This job only ever looks at the GATEWAY log, so it produces gateway-level /
general statistics: per service, per endpoint and per scenario.

Emits three key families so a single MapReduce pass builds all three reports:

    SVC|<service>    \\t <status_code>,<request_time_ms>
    EP|<endpoint>    \\t <status_code>,<request_time_ms>
    SCN|<scenario>   \\t <status_code>,<request_time_ms>

The endpoint is the request path without its query string, e.g.
/api/teams?name=Argentina -> /api/teams
"""
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
# common.py lives next to us on the cluster (shipped with -files) and in
# the parent directory when running the local debug pipeline.
sys.path.insert(0, _HERE)
sys.path.insert(0, os.path.dirname(_HERE))
from common import emit, from_csv, is_number  # noqa: E402


def main():
    for raw in sys.stdin:
        raw = raw.strip()
        if not raw:
            continue
        try:
            f = from_csv(raw)
        except Exception:
            continue
        if len(f) < 9:
            continue

        scenario = f[3] or "unknown"
        service = f[4] or "unknown"
        path = f[6] or "/"
        status_code = f[7]
        request_time_ms = f[8]

        if not (is_number(status_code) and is_number(request_time_ms)):
            continue

        endpoint = path.split("?", 1)[0]
        value = "%s,%s" % (int(float(status_code)), int(float(request_time_ms)))

        emit("SVC|%s" % service, value)
        emit("EP|%s" % endpoint, value)
        emit("SCN|%s" % scenario, value)


if __name__ == "__main__":
    main()

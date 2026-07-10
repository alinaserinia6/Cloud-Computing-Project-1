#!/usr/bin/env python3
"""
Job 1 — Parsing and Cleaning : MAPPER
=====================================
Input  : data/nginx/nginx_access.log        (JSON Lines, gateway log)
         data/service_logs/*_service.log    (JSON Lines, per-service logs)

The mapper auto-detects the record family from the fields present, validates
it, converts request_time_sec -> request_time_ms for the Nginx records, keeps
entity_type / entity_value for the service records, and emits a fixed schema.

An "invalid record" is a line whose JSON is broken, or which is missing a
mandatory field, or whose status_code / time field is not numeric.

Emitted format (Hadoop Streaming key/value):

    <dedupe_key> \\t <TAG> \\t <csv line>

TAG is one of NGINX / SERVICE / INVALID. The reducer keeps the first record
per dedupe_key (a request_id can never legitimately appear twice) and forwards
"<TAG>\\t<csv line>", which run_mapreduce.sh then splits into three files.
"""
import hashlib
import json
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
# common.py lives next to us on the cluster (shipped with -files) and in
# the parent directory when running the local debug pipeline.
sys.path.insert(0, _HERE)
sys.path.insert(0, os.path.dirname(_HERE))
from common import emit, is_number, to_csv  # noqa: E402

NGINX_FIELDS = ["timestamp", "request_id", "client_ip", "client_country",
                "scenario", "method", "path", "service", "status_code",
                "request_time_sec", "user_agent"]

SERVICE_FIELDS = ["timestamp", "request_id", "client_country", "service",
                  "endpoint", "entity_type", "entity_value", "status_code",
                  "processing_time_ms", "event_type"]

VALID_ENTITY_TYPES = {"team", "match_day", "stadium", "city"}


def invalid(source, reason, raw):
    raw = raw.replace("\t", " ").replace("\n", " ")[:300]
    digest = hashlib.md5(raw.encode("utf-8", "replace")).hexdigest()[:12]
    key = "INVALID|%s|%s" % (source, digest)
    emit(key, "INVALID\t" + to_csv([source, reason, raw]))


def handle_nginx(rec, raw):
    missing = [f for f in NGINX_FIELDS if f not in rec]
    if missing:
        return invalid("nginx", "missing_fields:" + "|".join(missing), raw)
    if not is_number(rec["status_code"]):
        return invalid("nginx", "non_numeric_status_code", raw)
    if not is_number(rec["request_time_sec"]):
        return invalid("nginx", "non_numeric_request_time", raw)
    if not str(rec["request_id"]).strip():
        return invalid("nginx", "empty_request_id", raw)

    # seconds (string) -> integer milliseconds
    request_time_ms = int(round(float(rec["request_time_sec"]) * 1000))
    if request_time_ms < 0:
        return invalid("nginx", "negative_request_time", raw)

    row = to_csv([
        rec["timestamp"], rec["request_id"], rec["client_country"],
        rec["scenario"] or "unknown", rec["service"] or "unknown",
        rec["method"], rec["path"], int(rec["status_code"]),
        request_time_ms, rec["user_agent"],
    ])
    emit("NGINX|%s" % rec["request_id"], "NGINX\t" + row)


def handle_service(rec, raw):
    missing = [f for f in SERVICE_FIELDS if f not in rec]
    if missing:
        return invalid("service", "missing_fields:" + "|".join(missing), raw)
    if not is_number(rec["status_code"]):
        return invalid("service", "non_numeric_status_code", raw)
    if not is_number(rec["processing_time_ms"]):
        return invalid("service", "non_numeric_processing_time", raw)
    if not str(rec["request_id"]).strip():
        return invalid("service", "empty_request_id", raw)
    if rec["entity_type"] not in VALID_ENTITY_TYPES:
        return invalid("service", "unknown_entity_type", raw)

    processing_time_ms = int(round(float(rec["processing_time_ms"])))
    if processing_time_ms < 0:
        return invalid("service", "negative_processing_time", raw)

    row = to_csv([
        rec["timestamp"], rec["request_id"], rec["client_country"],
        rec["service"], rec["endpoint"], rec["entity_type"],
        rec["entity_value"], int(rec["status_code"]),
        processing_time_ms, rec["event_type"],
    ])
    emit("SERVICE|%s|%s" % (rec["service"], rec["request_id"]), "SERVICE\t" + row)


def main():
    for raw in sys.stdin:
        raw = raw.strip()
        if not raw:
            continue
        try:
            rec = json.loads(raw)
        except ValueError:
            invalid("unknown", "broken_json", raw)
            continue
        if not isinstance(rec, dict):
            invalid("unknown", "not_a_json_object", raw)
            continue

        # Family detection: only the gateway log has request_time_sec / path,
        # only the service logs have entity_type.
        if "request_time_sec" in rec or "client_ip" in rec:
            handle_nginx(rec, raw)
        elif "entity_type" in rec or "event_type" in rec:
            handle_service(rec, raw)
        else:
            invalid("unknown", "unrecognized_schema", raw)


if __name__ == "__main__":
    main()

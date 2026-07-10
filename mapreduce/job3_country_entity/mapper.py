#!/usr/bin/env python3
"""
Job 3 — Country-Entity Request Count : MAPPER
=============================================
Input : cleaned_service_logs.csv (headerless), i.e. the Job 1 service output
        timestamp,request_id,client_country,service,endpoint,entity_type,
        entity_value,status_code,processing_time_ms,event_type

This is the first service-oriented job: its input is the per-service log,
NOT the Nginx log — only the services know which entity a request was about.

    team-service    -> entity_type = team
    match-service   -> entity_type = match_day
    stadium-service -> entity_type = stadium | city

MapReduce logic:
    Mapper : (country, service, entity_type, entity_value) -> 1
    Reducer: (country, service, entity_type, entity_value) -> sum
"""
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
# common.py lives next to us on the cluster (shipped with -files) and in
# the parent directory when running the local debug pipeline.
sys.path.insert(0, _HERE)
sys.path.insert(0, os.path.dirname(_HERE))
from common import emit, from_csv  # noqa: E402

VALID_ENTITY_TYPES = {"team", "match_day", "stadium", "city"}


def main():
    for raw in sys.stdin:
        raw = raw.strip()
        if not raw:
            continue
        try:
            f = from_csv(raw)
        except Exception:
            continue
        if len(f) < 10:
            continue

        country = f[2].strip()
        service = f[3].strip()
        entity_type = f[5].strip()
        entity_value = f[6].strip()

        # A request with no country or no entity carries no signal for this
        # analysis (e.g. a 400 caused by a missing query parameter).
        if not country or not entity_value:
            continue
        if entity_type not in VALID_ENTITY_TYPES:
            continue

        # '|' is our key separator; it never appears in the dataset, but be safe.
        key = "|".join(x.replace("|", "/") for x in
                       (entity_type, country, service, entity_value))
        emit(key, "1")


if __name__ == "__main__":
    main()

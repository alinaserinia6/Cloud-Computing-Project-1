#!/usr/bin/env python3
"""
Job 3 — Country-Entity Request Count : REDUCER
==============================================
Input  (sorted): entity_type|country|service|entity_value \\t 1
Output:          <TAG> \\t country,entity_value,total_requests

TAG maps 1:1 to one of the mandatory output files:
    TEAM     -> outputs/job3/country_team_requests.csv
    MATCHDAY -> outputs/job3/country_matchday_requests.csv
    STADIUM  -> outputs/job3/country_stadium_requests.csv
    CITY     -> outputs/job3/country_city_requests.csv   (extra, from ?city=)

Example:
    A,B,2
    A,Z,1
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

TAG_BY_ENTITY_TYPE = {
    "team": "TEAM",
    "match_day": "MATCHDAY",
    "stadium": "STADIUM",
    "city": "CITY",
}


def main():
    for key, values in group_by_key(read_lines()):
        parts = key.split("|")
        if len(parts) != 4:
            continue
        entity_type, country, _service, entity_value = parts
        tag = TAG_BY_ENTITY_TYPE.get(entity_type)
        if tag is None:
            continue

        total = 0
        for value in values:
            try:
                total += int(value)
            except ValueError:
                continue
        if total == 0:
            continue

        sys.stdout.write("%s\t%s\n" % (tag, to_csv([country, entity_value, total])))


if __name__ == "__main__":
    main()

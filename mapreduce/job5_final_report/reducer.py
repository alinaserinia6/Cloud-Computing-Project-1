#!/usr/bin/env python3
"""
Job 5 — Final Report Generation : REDUCER
=========================================
Combines the gateway-level statistics (Job 2, from nginx_access.log) with the
service-oriented results (Job 3 / Job 4, from the per-service logs) and writes
the final report of the project to stdout as JSON.

run_mapreduce.sh redirects it to:  outputs/final/summary.json

The four "predicted_*" fields come from the tournament prediction dataset that
match-service exposes (data/predictions/tournament_prediction.json). It is
shipped to the task working directory with `-files`, so this reducer never
hard-codes a champion.
"""
import io
import json
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
# common.py lives next to us on the cluster (shipped with -files) and in
# the parent directory when running the local debug pipeline.
sys.path.insert(0, _HERE)
sys.path.insert(0, os.path.dirname(_HERE))
from common import from_csv, group_by_key, read_lines  # noqa: E402

PREDICTION_FILE = "tournament_prediction.json"


def load_predictions():
    for candidate in (PREDICTION_FILE,
                      os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                   PREDICTION_FILE)):
        if os.path.exists(candidate):
            with io.open(candidate, encoding="utf-8") as fh:
                return json.load(fh)
    return {}


def argmax(mapping, key_fn):
    """Deterministic argmax: highest value wins, ties broken alphabetically."""
    if not mapping:
        return None
    return sorted(mapping.items(), key=lambda kv: (-key_fn(kv[1]), kv[0]))[0][0]


def main():
    svc = {}        # service  -> stats dict
    endpoint = {}   # endpoint -> stats dict
    scenario = {}   # scenario -> stats dict
    totals = {"team": {}, "match_day": {}, "stadium": {}, "city": {}}
    per_country = {"team": {}, "match_day": {}, "stadium": {}, "city": {}}
    popular = {"team": {}, "match_day": {}, "stadium": {}, "city": {}}

    entity_of_tag = {"TEAM": "team", "MATCHDAY": "match_day",
                     "STADIUM": "stadium", "CITY": "city"}
    pop_of_tag = {"POP_TEAM": "team", "POP_MATCHDAY": "match_day",
                  "POP_STADIUM": "stadium", "POP_CITY": "city"}

    for _key, values in group_by_key(read_lines()):
        for value in values:
            if "|" not in value:
                continue
            tag, row = value.split("|", 1)
            try:
                f = from_csv(row)
            except Exception:
                continue

            if tag in ("SVC", "EP", "SCN") and len(f) >= 7:
                stats = {
                    "total_requests": int(f[1]),
                    "success_count": int(f[2]),
                    "error_4xx": int(f[3]),
                    "error_5xx": int(f[4]),
                    "error_rate": float(f[5]),
                    "avg_response_time_ms": float(f[6]),
                }
                {"SVC": svc, "EP": endpoint, "SCN": scenario}[tag][f[0]] = stats

            elif tag in entity_of_tag and len(f) >= 3:
                kind = entity_of_tag[tag]
                country, entity, count = f[0], f[1], int(f[2])
                totals[kind][entity] = totals[kind].get(entity, 0) + count
                per_country[kind].setdefault(country, {})
                per_country[kind][country][entity] = \
                    per_country[kind][country].get(entity, 0) + count

            elif tag in pop_of_tag and len(f) >= 3:
                popular[pop_of_tag[tag]][f[0]] = f[1]

    predictions = load_predictions()

    total_requests = sum(s["total_requests"] for s in svc.values())
    total_4xx = sum(s["error_4xx"] for s in svc.values())
    total_5xx = sum(s["error_5xx"] for s in svc.values())

    # Gateway-level: ignore the synthetic "unknown" bucket when picking winners
    real_svc = {k: v for k, v in svc.items() if k not in ("unknown", "nginx")}
    real_ep = {k: v for k, v in endpoint.items() if k.startswith("/api/")}

    summary = {
        # ---- required by the spec ------------------------------------
        "total_requests": total_requests,
        "most_requested_service": argmax(real_svc, lambda s: s["total_requests"]),
        "highest_error_rate_service": argmax(real_svc, lambda s: s["error_rate"]),
        "slowest_endpoint": argmax(real_ep, lambda s: s["avg_response_time_ms"]),
        "most_popular_team_overall": argmax(totals["team"], lambda c: c),
        "most_requested_match_day_overall": argmax(totals["match_day"], lambda c: c),
        "most_requested_stadium_overall": argmax(totals["stadium"], lambda c: c),
        "popular_team_by_country": dict(sorted(popular["team"].items())),
        "predicted_champion": predictions.get("champion"),
        "predicted_final": predictions.get("final"),
        "predicted_final_winner": predictions.get("final_winner"),
        "predicted_final_stadium": predictions.get("final_stadium"),

        # ---- extra context (not required, but useful in the report) ---
        "overall_error_rate": round((total_4xx + total_5xx) / float(total_requests), 4)
        if total_requests else 0.0,
        "total_4xx": total_4xx,
        "total_5xx": total_5xx,
        "most_requested_city_overall": argmax(totals["city"], lambda c: c),
        "service_stats": dict(sorted(svc.items())),
        "endpoint_stats": dict(sorted(endpoint.items())),
        "scenario_stats": dict(sorted(scenario.items())),
        "popular_match_day_by_country": dict(sorted(popular["match_day"].items())),
        "popular_stadium_by_country": dict(sorted(popular["stadium"].items())),
        "popular_city_by_country": dict(sorted(popular["city"].items())),
        "distinct_countries": len(per_country["team"]),
    }

    sys.stdout.write(json.dumps(summary, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()

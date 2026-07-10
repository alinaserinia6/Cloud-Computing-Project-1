#!/usr/bin/env python3
"""
traffic-generator
=================
Plays the role of real users of the World Cup information system.

It ONLY ever talks to Nginx (--nginx-url). It never touches a backend
service directly — the backend ports are not even published to the host.

Usage
-----
    python traffic-generator/generate.py --requests 1000              # debug run
    python traffic-generator/generate.py --requests 100000            # final run

Every request carries the three headers required by the spec:

    X-Request-ID:     req_000001
    X-Client-Country: Iran
    X-Scenario:       normal

Mandatory traffic scenarios produced by this generator
------------------------------------------------------
  normal         normal requests to all three services
  hot_entity     skewed traffic: one team / one match day / one stadium
                 receive far more requests than the rest
  slow           requests that make the service respond slowly
                 (so response-time analysis becomes meaningful)
  invalid_input  bad input -> 4xx responses (400 / 404)
  server_error   requests that force a 5xx response

Requests are spread over several client countries via X-Client-Country,
which is what "which team is each country a fan of" analysis is built on.
The country is NOT derived from the IP, as the spec allows.

The optional --trace-file is a DEBUG aid only. It is never an input of the
MapReduce pipeline: the analysis inputs are nginx_access.log and the
per-service logs.
"""
import argparse
import csv
import random
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlencode

import requests
from requests.adapters import HTTPAdapter

# ---------------------------------------------------------------------------
# Datasets — must stay consistent with the backend in-memory "databases"
# ---------------------------------------------------------------------------
COUNTRIES = [
    ("Iran", 18), ("Germany", 14), ("Brazil", 13), ("USA", 12),
    ("Argentina", 11), ("France", 9), ("Japan", 7), ("Mexico", 6),
    ("Spain", 5), ("Canada", 3), ("Morocco", 2),
]

TEAMS = [
    "Argentina", "Brazil", "France", "Germany", "Spain", "England", "Portugal",
    "Netherlands", "Belgium", "Croatia", "Italy", "Uruguay", "Colombia",
    "Japan", "South Korea", "Australia", "Saudi Arabia", "Iran",
    "Morocco", "Senegal", "Nigeria", "USA", "Mexico", "Canada",
    "Denmark", "Switzerland", "Norway", "Sweden", "Ecuador", "Serbia",
]

MATCH_DAYS = [
    "2026-06-12", "2026-06-13", "2026-06-14", "2026-06-15", "2026-06-18",
    "2026-06-19", "2026-06-22", "2026-06-25", "2026-06-28", "2026-06-29",
    "2026-07-04", "2026-07-06", "2026-07-14", "2026-07-19",
]

STADIUMS = [
    "New York New Jersey Stadium", "Dallas Stadium", "Mexico City Stadium",
    "Los Angeles Stadium", "Miami Stadium", "Atlanta Stadium",
    "Houston Stadium", "Kansas City Stadium", "Boston Stadium",
    "Seattle Stadium", "Philadelphia Stadium", "Toronto Stadium",
    "BC Place Vancouver", "Monterrey Stadium", "Guadalajara Stadium",
    "San Francisco Bay Area Stadium",
]

CITIES = [
    "New York New Jersey", "Dallas", "Mexico City", "Miami", "Atlanta",
    "Houston", "Vancouver", "Seattle", "Toronto", "Los Angeles",
]

# Deliberate skew so that "most popular X overall" is unambiguous
HOT_TEAM = "Argentina"
HOT_MATCH_DAY = "2026-06-25"
HOT_STADIUM = "New York New Jersey Stadium"

# Each country has a favourite team -> makes Job 4 output meaningful
COUNTRY_FAVOURITE = {
    "Iran": "Argentina",
    "Germany": "Germany",
    "Brazil": "Brazil",
    "USA": "USA",
    "Argentina": "Argentina",
    "France": "France",
    "Japan": "Japan",
    "Mexico": "Mexico",
    "Spain": "Spain",
    "Canada": "Canada",
    "Morocco": "Morocco",
}

INVALID_TEAMS = ["Atlantis", "Wakanda", "Genovia", "El Dorado", ""]
INVALID_DATES = ["2026-13-45", "not-a-date", "25-06-2026", "", "2026-02-30"]
INVALID_STADIUMS = ["Old Trafford", "Camp Nou", "Wembley Stadium", ""]

# Service traffic share -> team-service becomes most_requested_service
SERVICE_WEIGHTS = [("team", 45), ("match", 30), ("stadium", 25)]

# Scenario mix (percentages). 4xx comes from invalid_input, 5xx from server_error.
SCENARIO_WEIGHTS = [
    ("normal", 56),
    ("hot_entity", 24),
    ("slow", 7),
    ("invalid_input", 9),
    ("server_error", 4),
]

_counter_lock = threading.Lock()
_counter = 0
_stats_lock = threading.Lock()
_stats = {"ok": 0, "4xx": 0, "5xx": 0, "failed": 0}


def _weighted(pairs):
    population = [p[0] for p in pairs]
    weights = [p[1] for p in pairs]
    return random.choices(population, weights=weights, k=1)[0]


def next_request_id():
    global _counter
    with _counter_lock:
        _counter += 1
        return "req_%06d" % _counter


def build_request(scenario):
    """Return (path, query_dict) for one request under the given scenario."""
    service = _weighted(SERVICE_WEIGHTS)

    if scenario == "invalid_input":
        # bias invalid input towards stadium-service so that it clearly has
        # the highest error rate in Job 2
        service = _weighted([("stadium", 55), ("team", 25), ("match", 20)])
        if service == "team":
            return "/api/teams", {"name": random.choice(INVALID_TEAMS)}
        if service == "match":
            return "/api/matches", {"date": random.choice(INVALID_DATES)}
        return "/api/stadiums", {"name": random.choice(INVALID_STADIUMS)}

    if scenario == "slow":
        # bias slow traffic towards /api/stadiums -> slowest_endpoint
        service = _weighted([("stadium", 60), ("team", 20), ("match", 20)])

    if scenario == "hot_entity":
        if service == "team":
            return "/api/teams", {"name": HOT_TEAM}
        if service == "match":
            return "/api/matches", {"date": HOT_MATCH_DAY}
        return "/api/stadiums", {"name": HOT_STADIUM}

    # normal / slow / server_error -> spread over the whole dataset
    if service == "team":
        return "/api/teams", {"name": random.choice(TEAMS)}
    if service == "match":
        return "/api/matches", {"date": random.choice(MATCH_DAYS)}
    # 80% stadium lookups by name, 20% by city
    if random.random() < 0.8:
        return "/api/stadiums", {"name": random.choice(STADIUMS)}
    return "/api/stadiums", {"city": random.choice(CITIES)}


def pick_country_and_team(scenario, path, query):
    """Give each country a favourite team, so Job 4 has a real signal."""
    country = _weighted(COUNTRIES)
    if path == "/api/teams" and scenario in ("normal", "hot_entity"):
        # 55% of a country's team lookups go to its favourite team
        if random.random() < 0.55:
            query = {"name": COUNTRY_FAVOURITE.get(country, HOT_TEAM)}
    return country, query


def one_request(session, base_url, timeout, trace_writer):
    scenario = _weighted(SCENARIO_WEIGHTS)
    path, query = build_request(scenario)
    country, query = pick_country_and_team(scenario, path, query)

    # X-Scenario understood by the services is "slow" / "server_error";
    # "hot_entity" and "invalid_input" behave like normal requests but are
    # still recorded in the logs so we can aggregate per scenario.
    request_id = next_request_id()
    headers = {
        "X-Request-ID": request_id,
        "X-Client-Country": country,
        "X-Scenario": scenario,
        "User-Agent": "traffic-generator",
    }

    url = base_url + path
    if query:
        url = url + "?" + urlencode(query)

    started = time.perf_counter()
    try:
        resp = session.get(url, headers=headers, timeout=timeout)
        status = resp.status_code
    except requests.RequestException as exc:
        with _stats_lock:
            _stats["failed"] += 1
        if trace_writer:
            trace_writer(request_id, country, scenario, url, "ERR", 0)
        print("request failed: %s" % exc, file=sys.stderr)
        return

    elapsed_ms = int((time.perf_counter() - started) * 1000)
    with _stats_lock:
        if status >= 500:
            _stats["5xx"] += 1
        elif status >= 400:
            _stats["4xx"] += 1
        else:
            _stats["ok"] += 1

    if trace_writer:
        trace_writer(request_id, country, scenario, url, status, elapsed_ms)


def main():
    parser = argparse.ArgumentParser(description="World Cup traffic generator")
    parser.add_argument("--nginx-url", default="http://localhost:8080",
                        help="Base URL of the Nginx gateway (never a backend!)")
    parser.add_argument("--requests", type=int, default=1000,
                        help="How many requests to send (final run: >= 100000)")
    parser.add_argument("--concurrency", type=int, default=32,
                        help="Number of worker threads")
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument("--seed", type=int, default=1404,
                        help="RNG seed, for reproducible runs")
    parser.add_argument("--trace-file", default=None,
                        help="Optional DEBUG csv. Never used as a MapReduce input.")
    args = parser.parse_args()

    if "://" not in args.nginx_url:
        parser.error("--nginx-url must include the scheme, e.g. http://localhost:8080")

    random.seed(args.seed)
    base_url = args.nginx_url.rstrip("/")

    # Fail fast if the gateway is not reachable
    try:
        requests.get(base_url + "/health", timeout=5)
    except requests.RequestException as exc:
        print("Cannot reach Nginx at %s (%s). Is `docker compose up -d` running?"
              % (base_url, exc), file=sys.stderr)
        return 1

    trace_fh = None
    trace_writer = None
    if args.trace_file:
        trace_fh = open(args.trace_file, "w", newline="", encoding="utf-8")
        writer = csv.writer(trace_fh)
        writer.writerow(["request_id", "client_country", "scenario", "url",
                         "status_code", "client_elapsed_ms"])
        trace_lock = threading.Lock()

        def trace_writer(*row):  # noqa: F811
            with trace_lock:
                writer.writerow(row)

    session = requests.Session()
    adapter = HTTPAdapter(pool_connections=args.concurrency,
                          pool_maxsize=args.concurrency, max_retries=0)
    session.mount("http://", adapter)
    session.mount("https://", adapter)

    print("Sending %d requests to %s with %d workers ..."
          % (args.requests, base_url, args.concurrency))
    started = time.perf_counter()

    with ThreadPoolExecutor(max_workers=args.concurrency) as pool:
        futures = [pool.submit(one_request, session, base_url, args.timeout, trace_writer)
                   for _ in range(args.requests)]
        done = 0
        for fut in futures:
            fut.result()
            done += 1
            if done % 5000 == 0:
                print("  %d / %d done (%.0fs)" % (done, args.requests,
                                                  time.perf_counter() - started))

    if trace_fh:
        trace_fh.close()

    elapsed = time.perf_counter() - started
    total = sum(_stats.values())
    print("\nFinished %d requests in %.1fs (%.0f req/s)"
          % (total, elapsed, total / max(elapsed, 1e-9)))
    print("  2xx/3xx : %d" % _stats["ok"])
    print("  4xx     : %d" % _stats["4xx"])
    print("  5xx     : %d" % _stats["5xx"])
    print("  failed  : %d" % _stats["failed"])
    print("\nNginx gateway log : data/nginx/nginx_access.log")
    print("Service logs      : data/service_logs/*.log")
    return 0


if __name__ == "__main__":
    sys.exit(main())

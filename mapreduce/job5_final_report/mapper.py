#!/usr/bin/env python3
"""
Job 5 — Final Report Generation : MAPPER
========================================
Inputs (three HDFS paths, all passed with -input):
    /output/job2   gateway-level general statistics   (SVC / EP / SCN lines)
    /output/job3   service-oriented counts            (TEAM / MATCHDAY / ...)
    /output/job4   most popular entity per country    (POP_TEAM / ...)

Every record is already tagged by the job that produced it, so the mapper only
has to route all of them to one single reducer, which can then cross-reference
the three families and emit outputs/final/summary.json.

Emits:  SUMMARY \\t <TAG>|<csv row>
"""
import sys

KNOWN_TAGS = {
    "SVC", "EP", "SCN",
    "TEAM", "MATCHDAY", "STADIUM", "CITY",
    "POP_TEAM", "POP_MATCHDAY", "POP_STADIUM", "POP_CITY",
}


def main():
    for raw in sys.stdin:
        raw = raw.rstrip("\n").rstrip("\r")
        if not raw or "\t" not in raw:
            continue
        tag, row = raw.split("\t", 1)
        if tag not in KNOWN_TAGS:
            continue
        # single reduce key -> one reducer builds the whole report
        sys.stdout.write("SUMMARY\t%s|%s\n" % (tag, row))


if __name__ == "__main__":
    main()

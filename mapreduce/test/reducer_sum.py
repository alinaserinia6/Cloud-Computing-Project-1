#!/usr/bin/env python3
"""Educational smoke test (spec section 8.3): sum the counts."""
import sys

count = 0
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    key, value = line.split("\t")
    count += int(value)
print("total\t%d" % count)

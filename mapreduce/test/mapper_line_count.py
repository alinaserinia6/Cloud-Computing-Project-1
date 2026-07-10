#!/usr/bin/env python3
"""Educational smoke test (spec section 8.3): emit 1 for every input line."""
import sys

for line in sys.stdin:
    line = line.strip()
    if line:
        print("total\t1")

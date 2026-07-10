#!/usr/bin/env python3
"""
common.py
=========
Tiny helper module shared by every mapper and reducer.

It is shipped to the Hadoop cluster with `-files ...,common.py`, so it lands
in the task working directory and can simply be imported.
"""
import csv
import io
import sys


def to_csv(fields):
    """Render a list of values as one RFC-4180 CSV line (no trailing newline).

    Tabs and newlines are stripped, because Hadoop Streaming uses '\\t' as the
    key/value separator and '\\n' as the record separator.
    """
    buf = io.StringIO()
    writer = csv.writer(buf, lineterminator="")
    writer.writerow([
        str(f).replace("\t", " ").replace("\n", " ").replace("\r", " ")
        for f in fields
    ])
    return buf.getvalue()


def from_csv(line):
    """Parse one CSV line back into a list of strings."""
    return next(csv.reader(io.StringIO(line)))


def is_number(value):
    try:
        float(value)
        return True
    except (TypeError, ValueError):
        return False


def emit(key, value):
    """Write one Hadoop Streaming key/value pair to stdout."""
    sys.stdout.write("%s\t%s\n" % (key, value))


def read_lines(stream=None):
    """Yield stripped, non-empty lines from stdin (or the given stream)."""
    stream = stream if stream is not None else sys.stdin
    for line in stream:
        line = line.rstrip("\n").rstrip("\r")
        if line:
            yield line


def group_by_key(lines):
    """Group Hadoop Streaming reducer input (already sorted) by its key.

    Yields (key, [value, value, ...]). The key is everything before the first
    tab; the value is the remainder of the line.
    """
    current_key = None
    values = []
    for line in lines:
        if "\t" in line:
            key, value = line.split("\t", 1)
        else:
            key, value = line, ""
        if current_key is not None and key != current_key:
            yield current_key, values
            values = []
        current_key = key
        values.append(value)
    if current_key is not None:
        yield current_key, values

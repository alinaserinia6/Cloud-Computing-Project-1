#!/usr/bin/env python3
"""
export_nginx_log_batches.py
===========================
Spark Structured Streaming's file source only picks up *new files* in a
directory — appending to an existing file is invisible to it. This helper
therefore slices a growing JSON Lines log into small, numbered batch files
and drops them into the Spark input directory.

    python3 scripts/export_nginx_log_batches.py \
        --source data/nginx/nginx_access.log \
        --output data/stream/nginx \
        --batch-size 200

Add --follow to keep tailing the file while the traffic generator is running,
so you can watch the live output update in the Spark terminal.

The analysis source stays the Nginx log / the service logs — this script only
reshapes them into batches, it never invents data.
"""
import argparse
import os
import time


def flush(batch, out_dir, index, prefix):
    if not batch:
        return index
    tmp_path = os.path.join(out_dir, ".%s_%03d.jsonl.tmp" % (prefix, index))
    final_path = os.path.join(out_dir, "%s_%03d.jsonl" % (prefix, index))
    with open(tmp_path, "w", encoding="utf-8") as fh:
        fh.writelines(batch)
    # atomic rename: Spark never sees a half-written file
    os.rename(tmp_path, final_path)
    print("wrote %s (%d lines)" % (final_path, len(batch)))
    return index + 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", required=True, help="JSON Lines log to slice")
    ap.add_argument("--output", required=True, help="Spark input directory")
    ap.add_argument("--batch-size", type=int, default=200)
    ap.add_argument("--prefix", default="batch")
    ap.add_argument("--follow", action="store_true",
                    help="keep tailing the source file")
    ap.add_argument("--flush-interval", type=float, default=5.0,
                    help="with --follow: emit a partial batch after N idle seconds")
    args = ap.parse_args()

    os.makedirs(args.output, exist_ok=True)

    existing = [f for f in os.listdir(args.output) if f.startswith(args.prefix)]
    index = len(existing) + 1

    with open(args.source, "r", encoding="utf-8", errors="replace") as fh:
        batch = []
        last_flush = time.time()
        while True:
            line = fh.readline()
            if line:
                if line.strip():
                    batch.append(line if line.endswith("\n") else line + "\n")
                if len(batch) >= args.batch_size:
                    index = flush(batch, args.output, index, args.prefix)
                    batch = []
                    last_flush = time.time()
                continue

            # EOF
            if not args.follow:
                flush(batch, args.output, index, args.prefix)
                return
            if batch and (time.time() - last_flush) >= args.flush_interval:
                index = flush(batch, args.output, index, args.prefix)
                batch = []
                last_flush = time.time()
            time.sleep(0.5)


if __name__ == "__main__":
    main()

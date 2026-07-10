#!/usr/bin/env python3
"""
Spark Structured Streaming — bonus part (spec section 10)
=========================================================
Reads the *new* Nginx gateway log batches and the *new* per-service log
batches incrementally, and keeps five live results up to date:

  1. request count per short time window          (10-second tumbling windows)
  2. live error rate                              (4xx + 5xx over total)
  3. busiest service / endpoint right now         (top-N per micro-batch)
  4. most popular team per country, live          (from the service logs)
  5. average response time per short time window

Difference from the MapReduce part: MapReduce re-processes the whole log as a
batch, while Structured Streaming consumes only the newly arrived records and
updates the running aggregates.

Run:
    spark-submit --master local[*] \
        spark/streaming_app.py \
        --input data/stream/nginx \
        --service-input data/stream/service_logs \
        --checkpoint checkpoints/spark

Feed it with:
    python3 scripts/export_nginx_log_batches.py \
        --source data/nginx/nginx_access.log --output data/stream/nginx \
        --batch-size 200 --follow
"""
import argparse
import os

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import (IntegerType, StringType, StructField, StructType)

# ---------------------------------------------------------------------------
# Schemas — declared explicitly: schema inference is not allowed on a stream.
# NOTE: in the Nginx log, request_time_sec is stored as a STRING. It must be
# cast to double, otherwise the value silently becomes null.
# ---------------------------------------------------------------------------
NGINX_SCHEMA = StructType([
    StructField("timestamp", StringType()),
    StructField("request_id", StringType()),
    StructField("client_ip", StringType()),
    StructField("client_country", StringType()),
    StructField("scenario", StringType()),
    StructField("method", StringType()),
    StructField("path", StringType()),
    StructField("service", StringType()),
    StructField("status_code", IntegerType()),
    StructField("request_time_sec", StringType()),   # <- string on purpose
    StructField("user_agent", StringType()),
])

SERVICE_SCHEMA = StructType([
    StructField("timestamp", StringType()),
    StructField("request_id", StringType()),
    StructField("client_country", StringType()),
    StructField("scenario", StringType()),
    StructField("service", StringType()),
    StructField("endpoint", StringType()),
    StructField("entity_type", StringType()),
    StructField("entity_value", StringType()),
    StructField("status_code", IntegerType()),
    StructField("processing_time_ms", IntegerType()),
    StructField("event_type", StringType()),
])

WINDOW = "10 seconds"
WATERMARK = "1 minute"


def banner(title):
    print("\n" + "=" * 70)
    print("  " + title)
    print("=" * 70)


def show_top(df, epoch_id, title, order_col, group_cols, n=5):
    """foreachBatch sink: print the current top-N rows of a running aggregate."""
    if df.rdd.isEmpty():
        return
    banner("%s   (micro-batch %d)" % (title, epoch_id))
    (df.orderBy(F.col(order_col).desc(), *group_cols)
       .limit(n)
       .show(n, truncate=False))


def popular_team_by_country(df, epoch_id):
    """Live version of Job 4: argmax team per country."""
    if df.rdd.isEmpty():
        return
    from pyspark.sql.window import Window
    w = Window.partitionBy("client_country").orderBy(
        F.col("total_requests").desc(), F.col("entity_value").asc())
    top = (df.withColumn("rank", F.row_number().over(w))
             .filter(F.col("rank") == 1)
             .select(F.col("client_country").alias("country"),
                     F.col("entity_value").alias("popular_team"),
                     "total_requests")
             .orderBy("country"))
    banner("Most popular team per country — LIVE   (micro-batch %d)" % epoch_id)
    top.show(50, truncate=False)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True,
                    help="directory Spark watches for new Nginx log batches")
    ap.add_argument("--service-input", default=None,
                    help="directory Spark watches for new service log batches")
    ap.add_argument("--checkpoint", required=True)
    ap.add_argument("--output-dir", default=None,
                    help="optional: also write the windowed stats as CSV here")
    ap.add_argument("--trigger", default="5 seconds")
    args = ap.parse_args()

    for d in (args.input, args.checkpoint):
        os.makedirs(d, exist_ok=True)
    if args.service_input:
        os.makedirs(args.service_input, exist_ok=True)

    spark = (SparkSession.builder
             .appName("worldcup-live-log-analytics")
             .config("spark.sql.shuffle.partitions", "4")
             .config("spark.sql.streaming.schemaInference", "false")
             .getOrCreate())
    spark.sparkContext.setLogLevel("WARN")

    # ---------------- Nginx gateway stream ---------------------------------
    nginx = (spark.readStream
             .schema(NGINX_SCHEMA)
             .option("maxFilesPerTrigger", 2)
             .json(args.input))

    nginx = (nginx
             .withColumn("event_time", F.to_timestamp("timestamp"))
             # request_time_sec is a STRING -> cast, then convert to ms
             .withColumn("request_time_ms",
                         (F.col("request_time_sec").cast("double") * 1000))
             .withColumn("endpoint", F.split(F.col("path"), r"\?").getItem(0))
             .withColumn("is_error", F.col("status_code") >= F.lit(400))
             .withColumn("is_5xx", F.col("status_code") >= F.lit(500))
             .withWatermark("event_time", WATERMARK))

    queries = []

    # ---- 1 + 5: request count and avg response time per 10s window --------
    windowed = (nginx
                .groupBy(F.window("event_time", WINDOW), F.col("service"))
                .agg(F.count("*").alias("requests"),
                     F.round(F.avg("request_time_ms"), 1).alias("avg_response_time_ms"),
                     F.round(F.avg(F.col("is_error").cast("int")) * 100, 2).alias("error_rate_pct"))
                .select(F.col("window.start").alias("window_start"),
                        F.col("window.end").alias("window_end"),
                        "service", "requests", "avg_response_time_ms", "error_rate_pct"))

    queries.append(windowed.writeStream
                   .outputMode("update")
                   .format("console")
                   .option("truncate", False)
                   .option("numRows", 20)
                   .queryName("windowed_service_stats")
                   .trigger(processingTime=args.trigger)
                   .option("checkpointLocation", os.path.join(args.checkpoint, "windowed"))
                   .start())

    if args.output_dir:
        os.makedirs(args.output_dir, exist_ok=True)
        queries.append(windowed.writeStream
                       .outputMode("append")
                       .format("csv")
                       .option("header", True)
                       .option("path", os.path.join(args.output_dir, "windowed_service_stats"))
                       .option("checkpointLocation", os.path.join(args.checkpoint, "windowed_csv"))
                       .trigger(processingTime=args.trigger)
                       .queryName("windowed_service_stats_csv")
                       .start())

    # ---- 2: live global error rate ---------------------------------------
    error_rate = (nginx.groupBy(F.lit(1).alias("all"))
                  .agg(F.count("*").alias("total_requests"),
                       F.sum(F.col("is_error").cast("int")).alias("errors"),
                       F.sum(F.col("is_5xx").cast("int")).alias("errors_5xx"))
                  .withColumn("error_rate_pct",
                              F.round(F.col("errors") / F.col("total_requests") * 100, 2))
                  .drop("all"))

    queries.append(error_rate.writeStream
                   .outputMode("complete")
                   .format("console")
                   .option("truncate", False)
                   .queryName("live_error_rate")
                   .trigger(processingTime=args.trigger)
                   .option("checkpointLocation", os.path.join(args.checkpoint, "error_rate"))
                   .start())

    # ---- 3: busiest service / endpoint right now -------------------------
    busiest = (nginx.groupBy("service", "endpoint")
               .agg(F.count("*").alias("requests")))

    queries.append(busiest.writeStream
                   .outputMode("complete")
                   .foreachBatch(lambda df, eid: show_top(
                       df, eid, "Busiest service / endpoint", "requests",
                       ["service", "endpoint"]))
                   .queryName("busiest_endpoint")
                   .trigger(processingTime=args.trigger)
                   .option("checkpointLocation", os.path.join(args.checkpoint, "busiest"))
                   .start())

    # ---- 4: most popular team per country (service logs) ------------------
    if args.service_input:
        svc = (spark.readStream
               .schema(SERVICE_SCHEMA)
               .option("maxFilesPerTrigger", 2)
               .json(args.service_input))

        teams = (svc
                 .filter((F.col("entity_type") == "team") &
                         (F.col("entity_value").isNotNull()) &
                         (F.length(F.col("entity_value")) > 0) &
                         (F.col("client_country").isNotNull()))
                 .groupBy("client_country", "entity_value")
                 .agg(F.count("*").alias("total_requests")))

        queries.append(teams.writeStream
                       .outputMode("complete")
                       .foreachBatch(popular_team_by_country)
                       .queryName("popular_team_by_country_live")
                       .trigger(processingTime=args.trigger)
                       .option("checkpointLocation", os.path.join(args.checkpoint, "popular_team"))
                       .start())

    print("\nStreaming queries started: %s" % ", ".join(q.name for q in queries))
    print("Drop new *.jsonl files into %s to see the numbers update.\n" % args.input)

    spark.streams.awaitAnyTermination()


if __name__ == "__main__":
    main()

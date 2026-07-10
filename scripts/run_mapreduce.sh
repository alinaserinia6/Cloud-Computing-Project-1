#!/usr/bin/env bash
# =====================================================================
# run_mapreduce.sh — the whole Phase 1 batch pipeline, Job 1 .. Job 5
#
# Run it INSIDE the namenode container (the project root is mounted there
# as /project by hadoop/docker-compose.yml):
#
#     docker compose -f hadoop/docker-compose.yml up -d
#     docker exec -it namenode bash /project/scripts/run_mapreduce.sh
#
# What it does, in order:
#   1. creates the HDFS directories
#   2. uploads data/nginx/nginx_access.log + data/service_logs/*.log
#   3. removes the previous output of each job (Hadoop refuses to overwrite)
#   4. runs each job with Hadoop Streaming (python3 mapper / reducer)
#   5. pulls every part-* file back to outputs/ on the host
#   6. feeds the output of each job into the next one
#
# Final artefact:  outputs/final/summary.json
# =====================================================================
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/project}"
HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop-3.2.1}"
STREAMING_JAR="${STREAMING_JAR:-$HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.2.1.jar}"

MR="$PROJECT_DIR/mapreduce"
OUT="$PROJECT_DIR/outputs"
COMMON="$MR/common.py"

cd "$PROJECT_DIR"

if [ ! -f "$STREAMING_JAR" ]; then
  echo "ERROR: hadoop-streaming jar not found at $STREAMING_JAR" >&2
  echo "       Find it with:  find / -name 'hadoop-streaming*.jar' 2>/dev/null" >&2
  exit 1
fi

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

# tagged <TAG> <file>  ->  print every line whose first tab-field is <TAG>,
# with that tag stripped off (portable replacement for `grep -P | cut -f2-`).
tagged() {
  awk -v want="$1" -F'\t' '$1==want { sub(/^[^\t]*\t/, ""); print }' "$2"
}

run_job() {
  # run_job <name> <mapper.py> <reducer.py> <hdfs-output> <num-reducers> <extra-files> <input...>
  local name="$1"; shift
  local mapper="$1"; shift
  local reducer="$1"; shift
  local output="$1"; shift
  local reduces="$1"; shift
  local extra_files="$1"; shift

  local files="$mapper,$reducer,$COMMON"
  [ -n "$extra_files" ] && files="$files,$extra_files"

  local inputs=()
  for i in "$@"; do inputs+=(-input "$i"); done

  hdfs dfs -rm -r -f "$output" >/dev/null 2>&1 || true

  log "$name"
  hadoop jar "$STREAMING_JAR" \
    -D mapreduce.job.name="$name" \
    -D mapreduce.job.reduces="$reduces" \
    -files "$files" \
    -mapper "python3 $(basename "$mapper")" \
    -reducer "python3 $(basename "$reducer")" \
    "${inputs[@]}" \
    -output "$output"
}

# ---------------------------------------------------------------------
# 0. HDFS layout + input upload
# ---------------------------------------------------------------------
log "Preparing HDFS input"
hdfs dfs -mkdir -p /input /input/service_logs /clean

hdfs dfs -put -f "$PROJECT_DIR/data/nginx/nginx_access.log" /input/nginx_access.log
for svc in match team stadium; do
  src="$PROJECT_DIR/data/service_logs/${svc}_service.log"
  if [ -f "$src" ]; then
    hdfs dfs -put -f "$src" "/input/service_logs/${svc}_service.log"
  else
    echo "WARNING: $src is missing — did you run the traffic generator?" >&2
  fi
done
hdfs dfs -ls /input /input/service_logs

mkdir -p "$OUT/job1" "$OUT/job2" "$OUT/job3" "$OUT/job4" "$OUT/final"

# ---------------------------------------------------------------------
# Job 1 — Parsing and Cleaning
#   in : /input/nginx_access.log + /input/service_logs
#   out: cleaned_nginx_logs.csv, cleaned_service_logs.csv, invalid_logs.csv
# ---------------------------------------------------------------------
run_job "job1_parse_clean" \
  "$MR/job1_parse_clean/mapper.py" "$MR/job1_parse_clean/reducer.py" \
  /output/job1 2 "" \
  /input/nginx_access.log /input/service_logs

log "Job 1 -> outputs/job1/*.csv"
TMP1="$(mktemp)"
hdfs dfs -cat '/output/job1/part-*' > "$TMP1"

NGINX_HEADER='timestamp,request_id,client_country,scenario,service,method,path,status_code,request_time_ms,user_agent'
SERVICE_HEADER='timestamp,request_id,client_country,service,endpoint,entity_type,entity_value,status_code,processing_time_ms,event_type'
INVALID_HEADER='source,reason,raw_line'

tagged 'NGINX'   "$TMP1" | sort > "$OUT/job1/_nginx.body"   || true
tagged 'SERVICE' "$TMP1" | sort > "$OUT/job1/_service.body" || true
tagged 'INVALID' "$TMP1" | sort > "$OUT/job1/_invalid.body" || true

{ echo "$NGINX_HEADER";   cat "$OUT/job1/_nginx.body";   } > "$OUT/job1/cleaned_nginx_logs.csv"
{ echo "$SERVICE_HEADER"; cat "$OUT/job1/_service.body"; } > "$OUT/job1/cleaned_service_logs.csv"
{ echo "$INVALID_HEADER"; cat "$OUT/job1/_invalid.body"; } > "$OUT/job1/invalid_logs.csv"
rm -f "$TMP1"

# The HEADERLESS bodies go back to HDFS as the input of Job 2 / Job 3.
hdfs dfs -put -f "$OUT/job1/_nginx.body"   /clean/cleaned_nginx_logs.csv
hdfs dfs -put -f "$OUT/job1/_service.body" /clean/cleaned_service_logs.csv
rm -f "$OUT/job1/_nginx.body" "$OUT/job1/_service.body" "$OUT/job1/_invalid.body"

echo "  cleaned nginx   : $(( $(wc -l < "$OUT/job1/cleaned_nginx_logs.csv") - 1 )) records"
echo "  cleaned service : $(( $(wc -l < "$OUT/job1/cleaned_service_logs.csv") - 1 )) records"
echo "  invalid         : $(( $(wc -l < "$OUT/job1/invalid_logs.csv") - 1 )) records"

# ---------------------------------------------------------------------
# Job 2 — General Nginx Aggregation  (gateway log only)
# ---------------------------------------------------------------------
run_job "job2_nginx_agg" \
  "$MR/job2_nginx_agg/mapper.py" "$MR/job2_nginx_agg/reducer.py" \
  /output/job2 1 "" \
  /clean/cleaned_nginx_logs.csv

log "Job 2 -> outputs/job2/*.csv"
TMP2="$(mktemp)"
hdfs dfs -cat '/output/job2/part-*' > "$TMP2"
STAT_HEADER='name,total_requests,success_count,error_4xx,error_5xx,error_rate,avg_response_time_ms'

{ echo "${STAT_HEADER/name/service}";  tagged 'SVC' "$TMP2" | sort; } > "$OUT/job2/service_stats.csv"
{ echo "${STAT_HEADER/name/endpoint}"; tagged 'EP'  "$TMP2" | sort; } > "$OUT/job2/endpoint_stats.csv"
{ echo "${STAT_HEADER/name/scenario}"; tagged 'SCN' "$TMP2" | sort; } > "$OUT/job2/scenario_stats.csv"
rm -f "$TMP2"
head -n 5 "$OUT/job2/service_stats.csv"

# ---------------------------------------------------------------------
# Job 3 — Country-Entity Request Count  (service logs only)
# ---------------------------------------------------------------------
run_job "job3_country_entity" \
  "$MR/job3_country_entity/mapper.py" "$MR/job3_country_entity/reducer.py" \
  /output/job3 1 "" \
  /clean/cleaned_service_logs.csv

log "Job 3 -> outputs/job3/*.csv"
TMP3="$(mktemp)"
hdfs dfs -cat '/output/job3/part-*' > "$TMP3"
{ echo 'country,team,total_requests';      tagged 'TEAM'     "$TMP3" | sort; } > "$OUT/job3/country_team_requests.csv"
{ echo 'country,match_day,total_requests'; tagged 'MATCHDAY' "$TMP3" | sort; } > "$OUT/job3/country_matchday_requests.csv"
{ echo 'country,stadium,total_requests';   tagged 'STADIUM'  "$TMP3" | sort; } > "$OUT/job3/country_stadium_requests.csv"
{ echo 'country,city,total_requests';      tagged 'CITY'     "$TMP3" | sort; } > "$OUT/job3/country_city_requests.csv"
rm -f "$TMP3"
head -n 5 "$OUT/job3/country_team_requests.csv"

# ---------------------------------------------------------------------
# Job 4 — Popular Entity by Country  (input = raw Job 3 output on HDFS)
# ---------------------------------------------------------------------
run_job "job4_popular_entity" \
  "$MR/job4_popular_entity/mapper.py" "$MR/job4_popular_entity/reducer.py" \
  /output/job4 1 "" \
  /output/job3

log "Job 4 -> outputs/job4/*.csv"
TMP4="$(mktemp)"
hdfs dfs -cat '/output/job4/part-*' > "$TMP4"
{ echo 'country,popular_team,total_requests';      tagged 'POP_TEAM'     "$TMP4" | sort; } > "$OUT/job4/popular_team_by_country.csv"
{ echo 'country,popular_match_day,total_requests'; tagged 'POP_MATCHDAY' "$TMP4" | sort; } > "$OUT/job4/popular_matchday_by_country.csv"
{ echo 'country,popular_stadium,total_requests';   tagged 'POP_STADIUM'  "$TMP4" | sort; } > "$OUT/job4/popular_stadium_by_country.csv"
{ echo 'country,popular_city,total_requests';      tagged 'POP_CITY'     "$TMP4" | sort; } > "$OUT/job4/popular_city_by_country.csv"
rm -f "$TMP4"
cat "$OUT/job4/popular_team_by_country.csv"

# ---------------------------------------------------------------------
# Job 5 — Final Report Generation (Job 2 + Job 3 + Job 4 -> summary.json)
# ---------------------------------------------------------------------
run_job "job5_final_report" \
  "$MR/job5_final_report/mapper.py" "$MR/job5_final_report/reducer.py" \
  /output/job5 1 "$PROJECT_DIR/data/predictions/tournament_prediction.json" \
  /output/job2 /output/job3 /output/job4

log "Job 5 -> outputs/final/summary.json"
hdfs dfs -cat '/output/job5/part-*' > "$OUT/final/summary.json"
cat "$OUT/final/summary.json"

log "Pipeline finished. Final report: outputs/final/summary.json"

#!/usr/bin/env bash
# =====================================================================
# local_pipeline_test.sh — DEBUG ONLY
#
# Runs the exact same mappers and reducers as scripts/run_mapreduce.sh,
# but with a plain `cat | mapper | sort | reducer` chain instead of
# Hadoop Streaming (the technique described in section 8.3 of the spec).
#
#     bash scripts/local_pipeline_test.sh              # writes to outputs_local/
#
# It is useful to iterate quickly on the mapper/reducer logic. It does NOT
# replace Hadoop Streaming: the deliverable outputs in outputs/ must be
# produced by scripts/run_mapreduce.sh inside the Hadoop cluster.
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DATA_DIR="${DATA_DIR:-data}"
OUT="${OUT:-outputs_local}"
MR="mapreduce"
export PYTHONPATH="$ROOT/$MR:${PYTHONPATH:-}"

mkdir -p "$OUT/job1" "$OUT/job2" "$OUT/job3" "$OUT/job4" "$OUT/final" "$OUT/.tmp"

tagged() { awk -v want="$1" -F'\t' '$1==want { sub(/^[^\t]*\t/, ""); print }' "$2"; }

echo "==> Job 1: parse & clean"
cat "$DATA_DIR"/nginx/nginx_access.log "$DATA_DIR"/service_logs/*.log \
  | python3 "$MR/job1_parse_clean/mapper.py" \
  | sort \
  | python3 "$MR/job1_parse_clean/reducer.py" > "$OUT/.tmp/job1.tsv"

NGINX_HEADER='timestamp,request_id,client_country,scenario,service,method,path,status_code,request_time_ms,user_agent'
SERVICE_HEADER='timestamp,request_id,client_country,service,endpoint,entity_type,entity_value,status_code,processing_time_ms,event_type'

tagged 'NGINX'   "$OUT/.tmp/job1.tsv" | sort > "$OUT/.tmp/nginx.csv"
tagged 'SERVICE' "$OUT/.tmp/job1.tsv" | sort > "$OUT/.tmp/service.csv"
{ echo "$NGINX_HEADER";   cat "$OUT/.tmp/nginx.csv";   } > "$OUT/job1/cleaned_nginx_logs.csv"
{ echo "$SERVICE_HEADER"; cat "$OUT/.tmp/service.csv"; } > "$OUT/job1/cleaned_service_logs.csv"
{ echo 'source,reason,raw_line'; tagged 'INVALID' "$OUT/.tmp/job1.tsv" | sort; } > "$OUT/job1/invalid_logs.csv"

echo "==> Job 2: general nginx aggregation"
python3 "$MR/job2_nginx_agg/mapper.py" < "$OUT/.tmp/nginx.csv" \
  | sort | python3 "$MR/job2_nginx_agg/reducer.py" > "$OUT/.tmp/job2.tsv"
H='total_requests,success_count,error_4xx,error_5xx,error_rate,avg_response_time_ms'
{ echo "service,$H";  tagged 'SVC' "$OUT/.tmp/job2.tsv" | sort; } > "$OUT/job2/service_stats.csv"
{ echo "endpoint,$H"; tagged 'EP'  "$OUT/.tmp/job2.tsv" | sort; } > "$OUT/job2/endpoint_stats.csv"
{ echo "scenario,$H"; tagged 'SCN' "$OUT/.tmp/job2.tsv" | sort; } > "$OUT/job2/scenario_stats.csv"

echo "==> Job 3: country-entity request count"
python3 "$MR/job3_country_entity/mapper.py" < "$OUT/.tmp/service.csv" \
  | sort | python3 "$MR/job3_country_entity/reducer.py" > "$OUT/.tmp/job3.tsv"
{ echo 'country,team,total_requests';      tagged 'TEAM'     "$OUT/.tmp/job3.tsv" | sort; } > "$OUT/job3/country_team_requests.csv"
{ echo 'country,match_day,total_requests'; tagged 'MATCHDAY' "$OUT/.tmp/job3.tsv" | sort; } > "$OUT/job3/country_matchday_requests.csv"
{ echo 'country,stadium,total_requests';   tagged 'STADIUM'  "$OUT/.tmp/job3.tsv" | sort; } > "$OUT/job3/country_stadium_requests.csv"
{ echo 'country,city,total_requests';      tagged 'CITY'     "$OUT/.tmp/job3.tsv" | sort; } > "$OUT/job3/country_city_requests.csv"

echo "==> Job 4: popular entity by country"
python3 "$MR/job4_popular_entity/mapper.py" < "$OUT/.tmp/job3.tsv" \
  | sort | python3 "$MR/job4_popular_entity/reducer.py" > "$OUT/.tmp/job4.tsv"
{ echo 'country,popular_team,total_requests';      tagged 'POP_TEAM'     "$OUT/.tmp/job4.tsv" | sort; } > "$OUT/job4/popular_team_by_country.csv"
{ echo 'country,popular_match_day,total_requests'; tagged 'POP_MATCHDAY' "$OUT/.tmp/job4.tsv" | sort; } > "$OUT/job4/popular_matchday_by_country.csv"
{ echo 'country,popular_stadium,total_requests';   tagged 'POP_STADIUM'  "$OUT/.tmp/job4.tsv" | sort; } > "$OUT/job4/popular_stadium_by_country.csv"
{ echo 'country,popular_city,total_requests';      tagged 'POP_CITY'     "$OUT/.tmp/job4.tsv" | sort; } > "$OUT/job4/popular_city_by_country.csv"

echo "==> Job 5: final report"
cp "$ROOT/data/predictions/tournament_prediction.json" "$OUT/.tmp/tournament_prediction.json"
cat "$OUT/.tmp/job2.tsv" "$OUT/.tmp/job3.tsv" "$OUT/.tmp/job4.tsv" \
  | python3 "$MR/job5_final_report/mapper.py" \
  | sort \
  | ( cd "$OUT/.tmp" && python3 "$ROOT/$MR/job5_final_report/reducer.py" ) \
  > "$OUT/final/summary.json"

rm -rf "$OUT/.tmp"
echo
echo "Done. Final report:"
head -c 1200 "$OUT/final/summary.json"; echo

# فاز اول پروژه پایانی — تحلیل لاگ جام جهانی با Nginx و MapReduce

مبانی رایانش ابری — نیمسال دوم ۱۴۰۴-۱۴۰۵

این مخزن شامل پیاده‌سازی کامل فاز اول است: سه سرویس `FastAPI` پشت `Nginx`،
یک تولیدکننده ترافیک، خط‌لوله‌ی پنج‌مرحله‌ای `Hadoop Streaming MapReduce`
و بخش امتیازی `Spark Structured Streaming`.

---

## ۱. ساختار پروژه

```txt
.
├── docker-compose.yml              # سرویس‌ها + Nginx
├── nginx/nginx.conf                # reverse proxy + لاگ JSON دروازه
├── match-service/                  # main.py + Dockerfile + requirements.txt
├── team-service/
├── stadium-service/
├── traffic-generator/generate.py   # کاربر آزمایشی (فقط از مسیر Nginx)
├── hadoop/                         # docker-compose نمونه‌ی کلاستر Hadoop
├── mapreduce/
│   ├── common.py                   # توابع مشترک mapper/reducerها
│   ├── job1_parse_clean/
│   ├── job2_nginx_agg/
│   ├── job3_country_entity/
│   ├── job4_popular_entity/
│   ├── job5_final_report/
│   └── test/                       # تست آموزشی بخش ۸.۳
├── scripts/
│   ├── run_mapreduce.sh            # اجرای Job1..Job5 روی Hadoop
│   ├── local_pipeline_test.sh      # اجرای محلی برای debug (بدون Hadoop)
│   └── export_nginx_log_batches.py # ساخت فایل‌های کوچک برای Spark
├── spark/streaming_app.py          # بخش امتیازی
├── data/
│   ├── nginx/nginx_access.log      # لاگ دروازه (خروجی اجرا)
│   ├── service_logs/*.log          # لاگ اختصاصی هر سرویس
│   └── predictions/                # داده‌ی پیش‌بینی قهرمانی
└── outputs/                        # خروجی‌های MapReduce
```

مسیر درخواست‌ها همیشه به این شکل است و **هرگز** مستقیم به backend نمی‌رود
(پورت سرویس‌ها اصلاً روی هاست publish نشده است):

```txt
traffic generator ---> Nginx :8080 ---> backend services
        |                  |                  |
        v                  v                  v
   (فقط تست)     data/nginx/nginx_access.log   data/service_logs/*.log
```

---

## ۲. اجرای سرویس‌ها و تولید ترافیک

```bash
# ۱) بالا آوردن سرویس‌ها و Nginx
docker compose up --build -d
docker compose ps
docker compose exec nginx nginx -t          # صحت کانفیگ

# ۲) تست دستی یک درخواست از مسیر Nginx
curl -H "X-Request-ID: manual-001" \
     -H "X-Client-Country: Iran" \
     -H "X-Scenario: normal" \
     "http://localhost:8080/api/teams?name=Argentina"

# ۳) دیدن خط لاگ تولیدشده
docker compose exec nginx sh -c "tail -n 5 /var/log/nginx/nginx_access.log"
tail -n 5 data/nginx/nginx_access.log
tail -n 5 data/service_logs/team_service.log
```

### تولید ترافیک

```bash
pip install -r traffic-generator/requirements.txt

# اجرای debug
python3 traffic-generator/generate.py --requests 1000 --nginx-url http://localhost:8080

# اجرای نهایی (حداقل ۱۰۰٬۰۰۰ درخواست)
python3 traffic-generator/generate.py --requests 100000 --nginx-url http://localhost:8080 --concurrency 64
```

سناریوهای اجباری‌ای که تولید می‌شوند:

| سناریو | توضیح | نتیجه در لاگ |
| --- | --- | --- |
| `normal` | درخواست عادی به هر سه سرویس | 2xx |
| `hot_entity` | ترافیک نامتوازن روی یک تیم/روز/ورزشگاه خاص | 2xx |
| `slow` | پاسخ کند سرویس | 2xx با `request_time` بالا |
| `invalid_input` | ورودی نامعتبر | 400 / 404 |
| `server_error` | خطای سمت سرور | 500 |

کشور کاربر از هدر `X-Client-Country` می‌آید (نه از روی IP) و هر کشور یک تیم
محبوب دارد، تا خروجی Job 4 معنادار باشد.

> نکته: گزینه‌ی `--trace-file` فقط برای debug است و هرگز ورودی MapReduce نیست.

### پاک‌سازی امن لاگ برای شروع یک اجرای تمیز

فایل لاگ زنده را حذف نکنید (Nginx در inode حذف‌شده می‌نویسد). به‌جای آن:

```bash
: > data/nginx/nginx_access.log          # truncate امن
: > data/service_logs/match_service.log
: > data/service_logs/team_service.log
: > data/service_logs/stadium_service.log
docker compose restart nginx
```

---

## ۳. فرمت لاگ‌ها

**`data/nginx/nginx_access.log`** — لاگ دروازه، مبنای تحلیل‌های عمومی:

```json
{"timestamp":"2026-06-25T12:00:01+00:00","request_id":"req_000001","client_ip":"172.18.0.1","client_country":"Iran","scenario":"normal","method":"GET","path":"/api/teams?name=Argentina","service":"team-service","status_code":200,"request_time_sec":"0.043","user_agent":"traffic-generator"}
```

**`data/service_logs/*_service.log`** — لاگ اختصاصی سرویس، مبنای تحلیل‌های سرویس‌محور:

```json
{"timestamp":"2026-06-25T12:00:01.043Z","request_id":"req_000001","client_country":"Iran","scenario":"normal","service":"team-service","endpoint":"/api/teams","entity_type":"team","entity_value":"Argentina","status_code":200,"processing_time_ms":31,"event_type":"team_lookup"}
```

`entity_type` بر اساس سرویس تعیین می‌شود:
`team` (team-service) · `match_day` (match-service) · `stadium` یا `city` (stadium-service).

---

## ۴. اجرای MapReduce

```bash
# بالا آوردن کلاستر Hadoop
docker compose -f hadoop/docker-compose.yml up -d
docker compose -f hadoop/docker-compose.yml ps
# NameNode UI : http://127.0.0.1:9870
# DataNode UI : http://127.0.0.1:9864

# اجرای کل خط‌لوله (Job 1 تا Job 5) داخل کانتینر namenode
docker exec -it namenode bash /project/scripts/run_mapreduce.sh
```

اسکریپت به‌ترتیب: پوشه‌های HDFS را می‌سازد، لاگ‌ها را با `hdfs dfs -put` بالا
می‌برد، خروجی قبلی هر job را با `hdfs dfs -rm -r -f` پاک می‌کند، jobها را با
Hadoop Streaming اجرا می‌کند و خروجی‌ها را با `hdfs dfs -cat` به `outputs/`
برمی‌گرداند. خروجی هر مرحله ورودی مرحله‌ی بعد است.

| Job | ورودی | خروجی |
| --- | --- | --- |
| 1 — Parsing & Cleaning | `/input/nginx_access.log` + `/input/service_logs/` | `cleaned_nginx_logs.csv`, `cleaned_service_logs.csv`, `invalid_logs.csv` |
| 2 — General Nginx Aggregation | `cleaned_nginx_logs.csv` | `service_stats.csv`, `endpoint_stats.csv`, `scenario_stats.csv` |
| 3 — Country-Entity Count | `cleaned_service_logs.csv` | `country_team_requests.csv`, `country_matchday_requests.csv`, `country_stadium_requests.csv` (+ `country_city_requests.csv`) |
| 4 — Popular Entity by Country | خروجی Job 3 | `popular_team_by_country.csv`, `popular_matchday_by_country.csv`, `popular_stadium_by_country.csv` (+ city) |
| 5 — Final Report | خروجی Job 2 + 3 + 4 | `outputs/final/summary.json` |

**Job 1** رکورد نامعتبر را جدا می‌کند (JSON خراب، فیلد اجباری غایب،
`status_code` یا زمان غیرعددی)، `request_time_sec` را به `request_time_ms`
تبدیل می‌کند و `entity_type` / `entity_value` تولیدشده توسط خود سرویس را نگه
می‌دارد. reducer آن رکوردهای تکراری (بر اساس `request_id`) را حذف می‌کند، تا
اجرای دوباره‌ی خط‌لوله idempotent باشد. چون لاگ‌ها ساختاریافته تولید
می‌شوند، `invalid_logs.csv` معمولاً خالی یا خیلی کوچک است — این طبیعی است.

**Job 2** فقط از لاگ Nginx تغذیه می‌شود (تحلیل عمومی / gateway-level) و
**Job 3/4** فقط از لاگ سرویس‌ها (تحلیل سرویس‌محور)، دقیقاً مطابق دستورکار.

### تست دستی محیط Hadoop (بخش ۸.۳ دستورکار)

```bash
docker exec -it namenode bash
cd /project
cat data/nginx/nginx_access.log \
  | python3 mapreduce/test/mapper_line_count.py \
  | sort \
  | python3 mapreduce/test/reducer_sum.py
```

### debug سریع بدون Hadoop

```bash
bash scripts/local_pipeline_test.sh     # خروجی در outputs_local/
```

این فقط برای debug است و **جایگزین Hadoop Streaming نیست**؛ خروجی‌های تحویلی
باید با `scripts/run_mapreduce.sh` تولید شوند.

---

## ۵. مشاهده‌ی خروجی‌ها

```bash
python3 -m http.server 9000
# http://localhost:9000/outputs/final/summary.json
# http://localhost:9000/outputs/job2/service_stats.csv
# http://localhost:9000/outputs/job4/popular_team_by_country.csv
```

نمونه‌ی `outputs/final/summary.json`:

```json
{
  "total_requests": 100000,
  "most_requested_service": "team-service",
  "highest_error_rate_service": "stadium-service",
  "slowest_endpoint": "/api/stadiums",
  "most_popular_team_overall": "Argentina",
  "most_requested_match_day_overall": "2026-06-25",
  "most_requested_stadium_overall": "New York New Jersey Stadium",
  "popular_team_by_country": { "Iran": "Argentina", "Germany": "Germany" },
  "predicted_champion": "Argentina",
  "predicted_final": "France vs Argentina",
  "predicted_final_winner": "Argentina",
  "predicted_final_stadium": "New York New Jersey Stadium"
}
```

چهار فیلد `predicted_*` از `data/predictions/tournament_prediction.json`
خوانده می‌شوند (همان داده‌ی `PREDICTED_TOURNAMENT_RESULT` در match-service) و
با `-files` به reducer پنجم فرستاده می‌شوند.

---

## ۶. بخش امتیازی — Spark Structured Streaming

```bash
mkdir -p data/stream/nginx data/stream/service_logs checkpoints/spark

# ترمینال ۱ — اجرای Spark
docker compose -f spark/docker-compose.yml up
# یا بدون Docker:
spark-submit --master 'local[*]' spark/streaming_app.py \
    --input data/stream/nginx \
    --service-input data/stream/service_logs \
    --checkpoint checkpoints/spark

# ترمینال ۲ — تولید ترافیک از مسیر Nginx
python3 traffic-generator/generate.py --nginx-url http://localhost:8080 --requests 1000

# ترمینال ۳ — تبدیل خطوط جدید لاگ به فایل‌های کوچک (Spark فقط فایل جدید را می‌بیند)
python3 scripts/export_nginx_log_batches.py \
    --source data/nginx/nginx_access.log --output data/stream/nginx \
    --batch-size 200 --follow
python3 scripts/export_nginx_log_batches.py \
    --source data/service_logs/team_service.log --output data/stream/service_logs \
    --batch-size 200 --follow
```

خروجی‌های زنده‌ای که در terminal به‌روزرسانی می‌شوند:

1. تعداد درخواست در پنجره‌های ۱۰ ثانیه‌ای
2. `error rate` زنده
3. پرترافیک‌ترین سرویس / endpoint در لحظه
4. محبوب‌ترین تیم هر کشور روی جریان داده‌ی زنده
5. میانگین `response time` در پنجره‌های کوتاه

نکات پیاده‌سازی:

* `request_time_sec` در لاگ Nginx **رشته** است؛ در Spark حتماً به `double`
  کست شده است، وگرنه مقدارش `null` می‌شود.
* برای شروع تمیز: `rm -rf checkpoints/spark`
* تفاوت با MapReduce: MapReduce کل لاگ را به‌صورت batch پردازش می‌کند،
  اما Structured Streaming فقط رکوردهای تازه‌رسیده را می‌خواند و آمار را
  به‌صورت تدریجی به‌روزرسانی می‌کند.

---

## ۷. چک‌لیست تحویل

* [x] سورس کامل سه سرویس با لاگ‌گذاری ساختاریافته
* [x] `Dockerfile` هر سه سرویس + `requirements.txt`
* [x] `nginx/nginx.conf` و `docker-compose.yml`
* [x] `traffic-generator/generate.py`
* [x] `hadoop/docker-compose.yml` با volume mount هماهنگ (`/project`)
* [x] `data/nginx/nginx_access.log` و `data/service_logs/*.log` اجرای نهایی
* [x] mapper و reducer هر پنج job + `scripts/run_mapreduce.sh`
* [x] همه‌ی خروجی‌های میانی در `outputs/` و `outputs/final/summary.json`
* [x] بخش امتیازی: `spark/streaming_app.py`

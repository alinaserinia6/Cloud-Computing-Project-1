# گزارش فاز اول پروژه پایانی — مبانی رایانش ابری

**تحلیل لاگ جام جهانی با Nginx و MapReduce**

## ۱. معماری

```
traffic generator ---> Nginx (:8080) ---> match-service  (:8000)
                          |          ---> team-service   (:8000)
                          |          ---> stadium-service(:8000)
                          |                     |
                          v                     v
             data/nginx/nginx_access.log   data/service_logs/*.log
                    (تحلیل عمومی)            (تحلیل سرویس‌محور)
```

* پورت سرویس‌های backend روی هاست publish نشده است، پس تولیدکننده‌ی ترافیک
  به‌هیچ‌وجه نمی‌تواند Nginx را دور بزند.
* Nginx هدرهای `x-request-id`، `x-client-country` و `x-scenario` را به سرویس
  مقصد منتقل می‌کند و همان‌ها در لاگ ساختاریافته‌ی سرویس ثبت می‌شوند.
* `$request_time` در Nginx بر حسب ثانیه است و در Job 1 به `request_time_ms`
  تبدیل می‌شود.

---

## ۲. اجرای موفق کانتینرها

`docker compose ps`

![containers](screenshots/01_docker_compose_ps.png)

`docker compose exec nginx nginx -t`

![nginx -t](screenshots/02_nginx_t.png)

---

## ۳. تست درخواست از مسیر Nginx

```bash
curl -H "X-Request-ID: manual-001" \
     -H "X-Client-Country: Iran" \
     -H "X-Scenario: normal" \
     "http://localhost:8080/api/teams?name=Argentina"
```

![curl](screenshots/03_curl_through_nginx.png)

---

## ۴. اجرای traffic generator

```bash
python3 traffic-generator/generate.py --requests 100000 --nginx-url http://localhost:8080
```

![traffic generator](screenshots/04_traffic_generator.png)

تعداد کل درخواست‌های اجرای نهایی: ......  
توزیع سناریوها: `normal` / `hot_entity` / `slow` / `invalid_input` / `server_error`

---

## ۵. بخشی از لاگ نهایی Nginx

```bash
tail -n 3 data/nginx/nginx_access.log
```

![nginx log](screenshots/05_nginx_access_log.png)

## ۶. بخشی از لاگ نهایی سرویس‌ها

```bash
tail -n 2 data/service_logs/team_service.log
tail -n 2 data/service_logs/match_service.log
tail -n 2 data/service_logs/stadium_service.log
```

![service logs](screenshots/06_service_logs.png)

---

## ۷. اجرای Hadoop Streaming

```bash
docker compose -f hadoop/docker-compose.yml up -d
docker exec -it namenode bash /project/scripts/run_mapreduce.sh
```

![hadoop up](screenshots/07_hadoop_ps.png)
![namenode ui](screenshots/08_namenode_ui.png)
![streaming job](screenshots/09_hadoop_streaming_job.png)

`hdfs dfs -ls /input` و `hdfs dfs -ls /output`

![hdfs ls](screenshots/10_hdfs_ls.png)

---

## ۸. خروجی‌های میانی

| Job | فایل | توضیح |
|---|---|---|
| 1 | `outputs/job1/cleaned_nginx_logs.csv` | لاگ دروازه‌ی تمیزشده، با `request_time_ms` |
| 1 | `outputs/job1/cleaned_service_logs.csv` | لاگ سرویس‌ها با `entity_type`/`entity_value` |
| 1 | `outputs/job1/invalid_logs.csv` | رکوردهای نامعتبر (JSON خراب / فیلد غایب / مقدار غیرعددی) |
| 2 | `outputs/job2/service_stats.csv` | تعداد، خطای 4xx/5xx، error rate و میانگین زمان پاسخ هر سرویس |
| 2 | `outputs/job2/endpoint_stats.csv` | همان آمار به تفکیک endpoint |
| 2 | `outputs/job2/scenario_stats.csv` | همان آمار به تفکیک سناریو |
| 3 | `outputs/job3/country_*_requests.csv` | تعداد درخواست هر کشور برای هر موجودیت |
| 4 | `outputs/job4/popular_*_by_country.csv` | محبوب‌ترین موجودیت هر کشور |

![job outputs](screenshots/11_outputs.png)

نمونه‌ی `outputs/job2/service_stats.csv`:

```
service,total_requests,success_count,error_4xx,error_5xx,error_rate,avg_response_time_ms
match-service,...
stadium-service,...
team-service,...
```

نمونه‌ی `outputs/job4/popular_team_by_country.csv`:

```
country,popular_team,total_requests
Iran,Argentina,...
Germany,Germany,...
```

---

## ۹. خروجی نهایی — `outputs/final/summary.json`

![summary](screenshots/12_summary_json.png)

تفسیر:

* `most_requested_service` — پرمراجعه‌ترین سرویس (از لاگ Nginx).
* `highest_error_rate_service` — سرویسی که بیشترین نسبت خطا دارد؛ چون ترافیک
  `invalid_input` بیشتر به سمت stadium-service هدایت شده، این سرویس بالاترین
  error rate را دارد.
* `slowest_endpoint` — endpointی با بیشترین میانگین زمان پاسخ.
* `most_popular_team_overall` / `..._match_day_...` / `..._stadium_...` — از
  جمع خروجی Job 3 روی همه‌ی کشورها.
* `popular_team_by_country` — خروجی Job 4.
* `predicted_*` — از داده‌ی پیش‌بینی مسابقات (`data/predictions/`).

---

## ۱۰. بخش امتیازی — Spark Structured Streaming

```bash
spark-submit --master 'local[*]' spark/streaming_app.py \
    --input data/stream/nginx --service-input data/stream/service_logs \
    --checkpoint checkpoints/spark
```

![spark](screenshots/13_spark_streaming.png)

Spark با `readStream` پوشه‌ی ورودی را می‌پاید؛ هر فایل کوچک جدیدی که
`scripts/export_nginx_log_batches.py` می‌سازد به‌عنوان یک micro-batch خوانده
می‌شود. آمار در پنجره‌های ۱۰ ثانیه‌ای جمع می‌شود و با رسیدن داده‌ی تازه
به‌روزرسانی می‌شود؛ برخلاف MapReduce که هر بار کل لاگ را از نو پردازش می‌کند.

نکته‌ی مهم: `request_time_sec` در لاگ Nginx رشته است و در Spark به `double`
کست شده، وگرنه مقدارش `null` می‌شد.

---

## ۱۱. مشکلات و نکات

* حذف مستقیم فایل لاگ زنده باعث می‌شود Nginx در inode حذف‌شده بنویسد؛
  به‌جای آن از truncate امن (`: > file`) یا `restart` استفاده شد.
* مسیر `-output` در Hadoop نباید از قبل وجود داشته باشد؛ اسکریپت قبل از هر
  اجرا آن را با `hdfs dfs -rm -r -f` پاک می‌کند.
* `nginx.conf` کامل (شامل `events` و `http`) روی `/etc/nginx/nginx.conf`
  مانت شده است، نه داخل `conf.d/`.

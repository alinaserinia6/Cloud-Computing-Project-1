#import "@preview/tablem:0.1.0": *

#set page(
  header: stack(
    spacing: 0.3cm,
    text(dir: rtl, size: 11pt, fill: black.lighten(10%))[
     فاز اول پروژه
    ],
    line(length: 100%, stroke: (
      paint: black.lighten(65%),
      thickness: 0.8pt,
    )),
  ),
)

#set figure(supplement: "شکل", numbering: "۱")

#let fig(body, cap) = figure(
  body,
  caption: [
    #set text(dir: rtl)
    #cap
  ]
)

// ============================================================================
// ۱. معماری
// ============================================================================
= معماری

اجرای پروژه بر اساس معماری زیر طراحی شده است:

\

```
traffic generator ---> Nginx (:8080) ---> match-service  (:8000)
                          |                                         ---> team-service   (:8000)
                          |                                         ---> stadium-service(:8000)
                          |                                                     |
                          v                                                     v
             data/nginx/nginx_access.log           data/service_logs/*.log
                    (تحلیل عمومی)                                       (تحلیل سرویس‌محور)
```


نکات کلیدی معماری:

- پورت سرویس‌های backend روی هاست publish نشده است، بنابراین تولیدکننده‌ی ترافیک به‌هیچ‌وجه نمی‌تواند Nginx را دور بزند.
- Nginx هدرهای `x-request-id`، `x-client-country` و `x-scenario` را به سرویس
  مقصد منتقل می‌کند و همان‌ها در لاگ ساختاریافته‌ی سرویس ثبت می‌شوند.
- `$request_time` در Nginx بر حسب ثانیه است و در Job 1 به `request_time_ms`
  تبدیل می‌شود.


// ============================================================================
// ۲. اجرای موفق کانتینرها
// ============================================================================
= اجرای موفق سرویس ها

== سرویس match-service

#fig(
  image("/assets/image-21.png"),
  [رفتار درست],
)

#fig(
  image("/assets/image-22.png"),
  [تاریخ نامعتبر],
)

== سرویس team-service

#fig(
  image("/assets/image-23.png"),
  [رفتار درست],
)

#fig(
  image("/assets/image-24.png"),
  [کشور نامعتبر],
)

== سرویس stadium-service

#fig(
  image("/assets/image-25.png"),
  [رفتار درست],
)

#fig(
  image("/assets/image-26.png"),
  [ورزشگاه نامعتبر],
)

= اجرای موفق کانتینرها

خروجی دستور `docker compose ps` نشان‌دهنده‌ی اجرای صحیح تمام کانتینرها است:

#fig(
  image("/assets/image-3.png"),
  [وضعیت کانتینرها],
)

همچنین آزمون صحت تنظیمات Nginx با موفقیت انجام شد:

```bash
docker compose exec nginx nginx -t
```

#fig(
  image("/assets/image-2.png", width: 80%),
  [آزمون تنظیمات Nginx],
)

#pagebreak()

// ============================================================================
// ۳. تست درخواست از مسیر Nginx
// ============================================================================
= تست درخواست از مسیر Nginx

جهت تست اولیه‌ی سیستم، یک درخواست نمونه به Nginx ارسال شد:

```bash
curl -H "X-Request-ID: manual-001" \
     -H "X-Client-Country: Iran" \
     -H "X-Scenario: normal" \
     "http://localhost:8080/api/teams?name=Argentina"
```

#fig(
  image("/assets/image-5.png", width: 40%),
  [نتیجه‌ی درخواست تستی از مسیر nginx],
)

// ============================================================================
// ۴. اجرای traffic generator
// ============================================================================
= اجرای traffic generator

برای تولید بار سنگین بر روی سیستم، از اسکریپت تولیدکننده‌ی ترافیک استفاده شد:


```bash
python3 traffic-generator/generate.py --requests 10000 --nginx-url http://localhost:8080
```

#fig(
  image("/assets/image-6.png"),
  [اجرای تولیدکننده‌ی ترافیک با ۱۰٬۰۰۰ درخواست],
)

// ============================================================================
// ۵. بخشی از لاگ نهایی Nginx
// ============================================================================
= بخشی از لاگ نهایی Nginx

پس از تولید ترافیک، لاگ Nginx با استفاده از دستور زیر مشاهده شد:

```bash
tail -n 3 data/nginx/nginx_access.log
```

#fig(
  image("/assets/image-7.png"),
  [سه خط آخر لاگ Nginx],
)

#pagebreak()

// ============================================================================
// ۶. بخشی از لاگ نهایی سرویس‌ها
// ============================================================================
= بخشی از لاگ نهایی سرویس‌ها

به‌طور مشابه، لاگ سرویس‌ها نیز مشاهده شد:

```
tail -n 2 data/service_logs/team_service.log
tail -n 2 data/service_logs/match_service.log
tail -n 2 data/service_logs/stadium_service.log
```

#fig(
  image("/assets/image-8.png"),
  [
    دو خط آخر لاگ team_service
  ],
)

#fig(
  image("/assets/image-9.png"),
  [دو خط آخر لاگ match-service],
)

#fig(
  image("/assets/image-10.png"),
  [دو خط آخر لاگ stadium_service],
)


// ============================================================================
// ۷. اجرای Hadoop Streaming
// ============================================================================
= اجرای Hadoop Streaming

برای پردازش داده‌ها، Hadoop Streaming به‌کار گرفته شد:

```
docker compose -f hadoop/docker-compose.yml up -d
docker exec -it namenode bash /project/scripts/run_mapreduce.sh
```

#fig(
  image("/assets/image-11.png"),
  [ساخته شدن Hadoop],
)

#fig(
  image("/assets/image-12.png"),
  [وضعیت کانتینرهای Hadoop],
)

#fig(
  image("/assets/image-13.png"),
  [رابط کاربری NameNode],
)

#fig(
  image("/assets/image-14.png"),
  [اجرای Job های Hadoop Streaming],
)

```bash
hdfs dfs -ls /input
hdfs dfs -ls /output
```

#fig(
  image("/assets/image-15.png"),
  [محتویات HDFS قبل و بعد از پردازش],
)


// ============================================================================
// ۸. خروجی‌های میانی
// ============================================================================
= خروجی‌های میانی

پس از پردازش، فایل‌های زیر به‌عنوان خروجی‌های میانی تولید شدند:

#set text(dir: rtl)
#table(
  columns: (auto, auto, auto),
  stroke: 0.5pt,
  align: center + horizon,
  inset: 0.5em,
  [Job], [فایل], [توضیح],
  [1], [outputs/job1/cleaned_nginx_logs.csv], [لاگ دروازه‌ی تمیزشده، با `request_time_ms`],
  [1], [outputs/job1/cleaned_service_logs.csv], [لاگ سرویس‌ها با `entity_type`/`entity_value`],
  [1], [outputs/job1/invalid_logs.csv], [رکوردهای نامعتبر],
  [2], [outputs/job2/service_stats.csv], [تعداد، خطای 4xx/5xx، error rate و میانگین زمان پاسخ هر سرویس],
  [2], [outputs/job2/endpoint_stats.csv], [همان آمار به تفکیک endpoint],
  [2], [outputs/job2/scenario_stats.csv], [همان آمار به تفکیک سناریو],
  [3], [outputs/job3/country_\*_requests.csv], [تعداد درخواست هر کشور برای هر موجودیت],
  [4], [outputs/job4/popular_\*_by_country.csv], [محبوب‌ترین موجودیت هر کشور],
)

#set text(dir: auto)

#fig(
  image("/assets/image-17.png", width: 70%),
  [فایل‌های خروجی در پوشه‌ی outputs],
)

نمونه‌ی `outputs/job2/service_stats.csv`:

#fig(
  image("/assets/image-16.png"),
  [outputs/job2/service_stats.csv],
)

نمونه‌ی `outputs/job4/popular_team_by_country.csv`:

#fig(
  image("/assets/image-18.png"),
  [outputs/job4/popular_team_by_country.csv],
)

#pagebreak()

// ============================================================================
// ۹. خروجی نهایی
// ============================================================================
= خروجی نهایی — `outputs/final/summary.json`

#fig(
  image("/assets/image-19.png"),
  [محتوای فایل summary.json],
)

تفسیر:

- `most_requested_service`: پرمراجعه‌ترین سرویس (از لاگ Nginx).
- `highest_error_rate_service`: سرویسی که بیشترین نسبت خطا دارد؛ چون ترافیک
  `invalid_input` بیشتر به سمت stadium-service هدایت شده، این سرویس بالاترین
  error rate را دارد.
- `slowest_endpoint`: endpointی با بیشترین میانگین زمان پاسخ.
- `most_popular_team_overall` / `..._match_day_...` / `..._stadium_...` — از
  جمع خروجی Job 3 روی همه‌ی کشورها.
- `popular_team_by_country`: خروجی Job 4.
- `predicted_*`: از داده‌ی پیش‌بینی مسابقات (`data/predictions/`).

// ============================================================================
// ۱۰. بخش امتیازی — Spark Structured Streaming
// ============================================================================
= بخش امتیازی — Spark Structured Streaming

برای پردازش زمان‌واقعی از Spark Streaming استفاده شد:

```bash
docker compose -f spark/docker-compose.yml run --rm spark /opt/spark/bin/spark-submit --master 'local[*]' /project/spark/streaming_app.py --input /project/data/stream/nginx --service-input /project/data/stream/service_logs --checkpoint /project/checkpoints/spark
```

#fig(
  image("/assets/image-27.png"),
  [ساخت docker compose],
)

#fig(
  image("/assets/image-28.png"),
  [اجرای برنامه‌ی Spark Streaming],
)


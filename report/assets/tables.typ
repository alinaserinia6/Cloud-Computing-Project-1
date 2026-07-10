
#let table-1-2 = align(center, [
  #v(2.5%)
  #text(dir: rtl, table(
    columns: 3,
    inset: 8pt,
    stroke: gray + 1pt,
    align: center + horizon,
    table.header(
      table.cell(
        stroke: none,
        [],
      ),
      [*برنامه پذیرفته شده است*],
      [*برنامه پذیرفته نشده است*],
    ),
    [*سامانهٔ نوع درست است*], [برنامه حتما معتبر است], [برنامه ممکن است معتبر باشد],
    [*سامانهٔ نوع کامل است*], [برنامه ممکن است نامعتبر باشد], [برنامه حتما نامعتبر است],
  ))
  #text(
    dir: ltr,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      جدول ۱.۲: مقایسه درستی با کامل بودن سامانه‌های نوع
    ],
  )
  #v(1%)
])

#let table-2-2 = align(center, [
  #v(2.5%)
  #text(dir: rtl, table(
    columns: 5,
    inset: 8pt,
    stroke: gray + 1pt,
    align: center + horizon,
    table.header([*سامانهٔ نوع*], [*جابه‌جایی*], [*تضعیف*], [*انقباض*], [*نحوه استفاده از متغیرها*]),
    [*مرتب*], [-], [-], [-], [دقیقا یکبار به ترتیب معرفی],
    [*خطی*], [مجاز], [-], [-], [دقیقا یکبار],
    [*آفینی*], [مجاز], [مجاز], [-], [حداکثر یکبار],
    [*وابسته*], [مجاز], [-], [مجاز], [حداقل یکبار],
    [*معمولی*], [مجاز], [مجاز], [مجاز], [دلخواه],
  ))
  #text(
    dir: ltr,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      جدول ۲.۲: انواع سامانه‌های نوع زیرساختاری
    ],
  )
  #v(1%)
])

#let table-3-2 = align(center, [
  #v(2.5%)
  #text(dir: rtl, table(
    columns: 3,
    inset: 8pt,
    stroke: gray + 1pt,
    align: center + horizon,
    table.header(
      table.cell(
        stroke: none,
        [],
      ),
      [*بررسی ایستا*],
      [*بررسی پویا*],
    ),

    [*ایمن*], text(dir: ltr, [ML, Haskell, Java, Rust]), text(dir: ltr, [Lisp, Scheme, Perl]),

    [*ناایمن*], text(dir: ltr, [C, C++]), text(dir: ltr, [JavaScript]),
  ))
  #text(
    dir: ltr,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      جدول ۳.۲: مثال‌هایی از زبان‌های ایمن و غیرایمن با توجه به روش‌های بررسی نوع‌ها
    ],
  )
  #v(1%)
])

#let table-1-4 = align(center, [
  #v(2.5%)
  #text(dir: rtl, table(
    columns: 4,
    inset: 8pt,
    stroke: gray + 1pt,
    align: center + horizon,
    table.header(
      table.cell(
        colspan: 2,
        rowspan: 2,
        stroke: none,
        align: horizon,
        rotate(90deg, reflow: true)[],
      ),
      table.cell(colspan: 2, [*خروجی ابزار*]),
      [برنامه‌ دارای خطای حافظه است], [برنامه‌ بدون خطای حافظه است],
    ),
    table.cell(
      rowspan: 2,
      align: horizon,
      rotate(90deg, reflow: true)[*برچسب واقعی*],
    ),

    [برنامه‌ دارای خطای حافظه است], [۱۰۰ مورد], [۰ مورد],

    [برنامه‌ بدون خطای حافظه است], [۲۸ مورد], [۹۲ مورد],
  ))
  #text(
    dir: ltr,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      جدول ۱.۴: نتیجهٔ ارزیابی ابزار بر روی ۲۲۰ نمونهٔ آزمایشی
    ],
  )
  #v(1%)
])

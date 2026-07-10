
#import "@preview/cetz:0.4.0"
#import "@preview/cetz-plot:0.1.2": chart
#import "@preview/fletcher:0.5.8": diagram, edge, node

#import "core-c/syntactic-forms.typ"
#import "core-c/evaluation-rules.typ"
#import "core-c/typing-rules.typ"

#let figure-1-2 = align(center, [
  #v(2.5%)
  #rect(
    stroke: 0.5pt,
    width: 100%,
    align(left, text(dir: ltr, [
      #text(fill: black.lighten(35%), [
        *main.c*
      ])
      ```c

      #include <stdio.h>
      #include <stdlib.h>

      int main() {
              int *ptr_1 = malloc(sizeof(int) * 8);
              free(ptr_1);

              int *ptr_2 = malloc(sizeof(int) * 8);
              for (int i = 0; i < 8; i++) {
                      ptr_2[i] = i;
              }

              for (int i = 0; i < 8; i++) {
                      printf("%d ", ptr_1[i]);
              }
              printf("\n");

              return 0;
      }


      ```
    ])),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۱.۳: بد به کار بردن دسترسی به حافظه پس از آزادسازی
    ],
  )
  #v(1%)
])

#let figure-2-2 = align(center, [
  #v(2.5%)
  #rect(
    stroke: 0.5pt,
    width: 100%,
    align(left, text(dir: ltr, [
      #text(fill: black.lighten(35%), [
        *main.c*
      ])
      ```c

      #include <stdio.h>
      #include <stdlib.h>

      int main() {
              int *ptr_1 = malloc(sizeof(int) * 8);
              free(ptr_1);
              free(ptr_1);

              int *ptr_2 = malloc(sizeof(int) * 8);
              int *ptr_3 = malloc(sizeof(int) * 8);

              printf("ptr_1: %d\n", ptr_1);
              printf("ptr_2: %d\n", ptr_2);
              printf("ptr_3: %d\n", ptr_3);

              return 0;
      }


      ```
    ])),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۲.۳: بد به کار بردن آزادسازی دوبارهٔ حافظه
    ],
  )
  #v(1%)
])

#let figure-1-3 = align(center, [
  #v(2.5%)
  #syntactic-forms.type-and-value-syntactic-forms
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۱.۳: توصیف نحو نوع‌ها و مقدارها
    ],
  )
  #v(1%)
])

#let figure-2-3 = align(center, [
  #v(2.5%)
  #syntactic-forms.expression-and-operations-syntactic-forms
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۲.۳: توصیف نحو عبارت‌ها و عملیات‌ها
    ],
  )
  #v(1%)
])

#let figure-3-3 = align(center, [
  #v(2.5%)
  #syntactic-forms.statement-syntactic-forms
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۳.۳: توصیف نحو حکم‌ها
    ],
  )
  #v(1%)
])

#let figure-4-3 = align(center, [
  #v(2.5%)
  #syntactic-forms.program-syntactic-forms
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۴.۳: توصیف نحو برنامه
    ],
  )
  #v(1%)
])

#let figure-5-3 = align(center, [
  #v(2.5%)
  #evaluation-rules.fn-and-env-definitions
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۵.۳: توصیف محیط و مجموعهٔ توابع
    ],
  )
  #v(1%)
])

#let figure-6-3 = align(center, [
  #v(2.5%)
  #evaluation-rules.expression-evaluation-rules
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۶.۳: قاعده‌های ارزیابی عبارت‌ها
    ],
  )
  #v(1%)
])

#let figure-7-3 = align(center, [
  #v(2.5%)
  #evaluation-rules.statement-evaluation-rules
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۷.۳: قاعده‌های ارزیابی جمله‌ها
    ],
  )
  #v(1%)
])

#let figure-8-3 = align(center, [
  #v(2.5%)
  #evaluation-rules.program-evaluation-rules
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۸.۳: قاعده‌های ارزیابی برنامه
    ],
  )
  #v(1%)
])

#let figure-9-3 = align(center, [
  #v(2.5%)
  #typing-rules.gamma-and-delta-defenitions
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۹.۳: توصیف زمینهٔ نوع و زمینهٔ متغیرهای خطی
    ],
  )
  #v(1%)
])

#let figure-10-3 = align(center, [
  #v(2.5%)
  #typing-rules.operations-typing-rules
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۱۰.۳: قاعده‌های نوع‌دهی عملیات‌ها
    ],
  )
  #v(1%)
])

#let figure-11-3 = align(center, [
  #v(2.5%)
  #typing-rules.expression-typing-rules
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۱۱.۳: قاعده‌های نوع‌دهی عبارت‌ها
    ],
  )
  #v(1%)
])

#let figure-12-3 = align(center, [
  #v(2.5%)
  #typing-rules.statement-typing-rules
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۱۲.۳: قاعده‌های نوع‌دهی حکم‌ها
    ],
  )
  #v(1%)
])

#let figure-13-3 = align(center, [
  #v(2.5%)
  #typing-rules.program-typing-rules
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۱۳.۳: قاعده‌های نوع‌دهی برنامه
    ],
  )
  #v(1%)
])


#let figure-1-4 = align(center, [
  #v(1.5%)
  #text(
    dir: rtl,
    diagram(
      spacing: (1cm, 1cm),

      node((2, 0), rect(width: 115pt, height: 50pt, [
        دریافت فایل دستورهای
        \
        کامپایل پروژه
        #v(10%)
      ])),

      node((-2, 0), rect(width: 115pt, [
        جایگزینی کتابخانه‌های
        \
        استفاده شده با نسخهٔ
        \
        حاشیه‌نویسی شدهٔ آن‌ها
        #v(10%)
      ])),

      node((2, 1), rect(width: 115pt, height: 50pt, [
        انجام عملیات پیش‌پردازش
        #footnote[preprocessing]
        \
        روی کد و گسترش ماکروها
        #v(10%)
      ])),

      node((-2, 1), rect(width: 115pt, height: 50pt, [
        ساخت درخت نحو انتزاعی
        #v(10%)
      ])),

      node((2, 2), rect(width: 115pt, height: 50pt, [
        ساخت نمایش میانی
        \
        سطح بالا
        #footnote[HIR - high-level intermediate representation]
        #v(10%)
      ])),

      node((-2, 2), rect(width: 115pt, [
        ساخت نمایش میانی
        \
        سطح متوسط
        #footnote[MIR - mid-level intermediate representation]
        یا همان
        \
        گراف کنترل جریان
        #v(10%)
      ])),

      node((2, 3), rect(width: 115pt, height: 50pt, [
        تحلیل گراف کنترل جریان
        \
        براساس قوانین نوع خطی
        #v(10%)
      ])),

      node((-2, 3), rect(width: 115pt, height: 50pt, [
        گزارش خطاها
        #v(10%)
      ])),

      edge((2, 0), (-2, 0), "-|>"),
      edge((-2, 0), (2, 1), "-|>", bend: 5deg),
      edge((2, 1), (-2, 1), "-|>"),
      edge((-2, 1), (2, 2), "-|>", bend: 5deg),
      edge((2, 2), (-2, 2), "-|>"),
      edge((-2, 2), (2, 3), "-|>", bend: 5deg),
      edge((2, 3), (-2, 3), "-|>"),
    ),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(2%)
      شکل ۱.۴: نمودار بلوکی ابزار
    ],
  )
  #v(1%)
])


#let figure-2-4 = align(center, [
  #v(2.5%)
  #rect(
    stroke: 0.5pt,
    width: 50%,
    align(left, text(dir: ltr, [
      #text(fill: black.lighten(35%), [
        *main.c*
      ])
      ```c

      void main() {
              int i = 1 + 2 + 3;
              if (i < 10) {
                      i = 10;
              } else {
                      i = 100;
              }
              return;
      }


      ```
    ])),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۲.۴: قطعه کد ساده دارای شاخه
    ],
  )
  #v(1%)
])

#let figure-3-4 = align(center, [
  #v(1.5%)
  #rect(stroke: 0.5pt, width: 50%, align(left, grid(
    columns: 3,
    gutter: 6pt,
    text(dir: ltr, [
      \
      ```rust

      'bb_1: {
              i_2 = 10;
              goto 'bb_3;
      }

      'bb_2: {
              i_2 = 100;
              goto 'bb_3;
      }

      'bb_3: {
              return;
      }


      ```
    ]),

    line(angle: 90deg, length: 300pt, stroke: 0.5pt),

    text(dir: ltr, [
      #text(fill: black.lighten(35%), [
        *main.c*
      ])
      ```rust

      let main_0: void;
      let _1: temp;
      let i_2: int;
      let _3: temp;

      'bb_0: {
              _1 = 1 + 2;
              i_2 = _1 + 3;
              _3 = i_2 < 10;
              switch _3 {
                      1 => 'bb_1;
                      _ => 'bb_2;
              }
      }


      ```
    ]),
  )))
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۳.۴: نمایش گراف کنترل جریان برای یک قطعه کد ساده توسط ابزار
    ],
  )
  #v(1%)
])

#let figure-4-4 = align(center, [
  #v(1.5%)
  #text(
    dir: ltr,

    diagram(
      spacing: (1cm, 1cm),

      node((0, 0), rect("start")),

      node((0, 2), rect(```rust
      i = 1 + 2 + 3;
      if (i < 10)
      ```)),

      node((1, 4), rect(```rust
      i = 10;
      ```)),

      node((-1, 4), rect(```rust
      i = 100;
      ```)),

      node((0, 6), rect(width: 50pt, height: 15pt, [])),

      node((0, 8), rect("end")),

      edge((0, 0), (0, 2), "-|>"),
      edge((0, 2), (1, 4), "-|>", text("T")),
      edge((0, 2), (-1, 4), "-|>", text("F")),
      edge((1, 4), (0, 6), "-|>"),
      edge((-1, 4), (0, 6), "-|>"),
      edge((0, 6), (0, 8), "-|>"),
    ),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(2%)
      شکل ۴.۴: نمایش مرسوم گراف کنترل جریان برای یک قطعه کد ساده
    ],
  )
  #v(1%)
])

#let figure-5-4 = align(center, [
  #v(2.5%)
  #rect(stroke: 0.5pt, width: 100%, align(left, text(dir: ltr, [
    Consider these memory safety issues: use-after-free, memory-leak, double-free, dangling-pointer.
    Try to generate 100 C codes based on these which have memory issues.
    The scenarios must have function definition and function calling.
    Don't use struct, enum, and union, and global variables.
    Name the files as case-unsafe-1.c, ...
    Remove the comments and make them as diverse as possible.
    Don't copy the examples just learn the patterns and combine them in complicated scenarios.
    They must at least have three functions defined.

    \

    #h(-0.4cm)
    Consider these memory safety issues: use-after-free, memory-leak, double-free, dangling-pointer.
    Try to generate 120 C codes based on these which do not have memory issues.
    The scenarios must have function definition and function calling.
    Don't use struct, enum, and union, and global variables.
    Name the files as case-safe-1.c, ...
    Remove the comments and make them as diverse as possible.
    Don't copy the examples just learn the patterns and combine them in complicated scenarios.
    They must at least have three functions defined.

    \
  ])))
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۵.۴: دستورهای استفاده شده به‌منظور تولید نمونه‌های آزمایشی
    ],
  )
  #v(1%)
])

#let figure-6-4 = align(center, [
  #v(2.5%)
  #rect(
    stroke: 0.5pt,
    width: 100%,
    align(left, text(dir: ltr, [
      #text(fill: black.lighten(35%), [
        *main.c*
      ])
      ```c

      #include <azhdaha.h>
      #include <stdlib.h>

      LINEAR_TYPE int *create_pattern(int length) {
          LINEAR_TYPE int *pattern = malloc(length * sizeof(int));
          for (int i = 0; i < length; i++) {
              pattern[i] = i * 4;
          }
          return pattern;
      }

      void transform_pattern(LINEAR_TYPE int *pattern, int length) {
          for (int i = 0; i < length; i++) {
              pattern[i] * 2 + 1;
          }
          free(pattern);
      }

      int find_pattern_value(LINEAR_TYPE int *pattern, int length, int target) {
          for (int i = 0; i < length; i++) {
              if (pattern[i] == target) {
                  return i;
              }
          }
          return -1;
      }

      void main() {
          LINEAR_TYPE int *seq = create_pattern(30);
          transform_pattern(seq, 30);
          int pos = find_pattern_value(seq, 30, 15);
      }


      ```
    ])),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۶.۴: نمونهٔ برنامهٔ آزمایش شده که دارای ایراد حافظه است
    ],
  )
  #v(1%)
])

#let figure-7-4 = align(center, [
  #v(2.5%)
  #text(dir: rtl, cetz.canvas({
    let data = (([مثبت درست], 100), ([منفی غلط], 0), ([مثبت غلط], 28), ([منفی درست], 92))

    let colors = gradient.linear(red, blue, green, yellow)

    chart.piechart(
      data,
      label-key: 0,
      value-key: 1,
      radius: 4,
      slice-style: colors,
      inner-label: (content: (value, label) => [], radius: 110%),
      outer-label: (content: "%", radius: 60%),
    )
  }))
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۷.۴: نمودار دایره‌ای ارزیابی ابزار بر روی ۲۲۰ نمونهٔ آزمایشی
    ],
  )
  #v(1%)
])

#let figure-1-5 = align(center, [
  #v(2.5%)
  #rect(
    stroke: 0.5pt,
    width: 50%,
    align(left, text(dir: ltr, [
      #text(fill: black.lighten(35%), [
        *azhdaha.h*
      ])
      ```c

      #define LINEAR_TYPE

      ```
      \
    ])),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۱.۵: تعریف عمومی ماکروی نوع خطی
    ],
  )
  #v(1%)
])

#let figure-2-5 = align(center, [
  #v(2.5%)
  #rect(
    stroke: 0.5pt,
    width: 50%,
    align(left, text(dir: ltr, [
      #text(fill: black.lighten(35%), [
        *azhdaha.h*
      ])
      ```c

      #define LINEAR_TYPE linear_type


      ```
    ])),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۲.۵: تعریف اختصاصی ماکروی نوع خطی
    ],
  )
  #v(1%)
])

#let figure-3-5 = align(center, [
  #v(2.5%)
  #rect(
    stroke: 0.5pt,
    width: 100%,
    align(left, text(dir: ltr, [
      #text(fill: black.lighten(35%), [
        *stdlib.h*
      ])
      ```c

      /* Allocate SIZE bytes of memory.  */
      extern linear_type void *malloc (size_t __size);

      /* Free a block allocated by `malloc', `realloc' or `calloc'.  */
      extern void free (linear_type void *__ptr);


      ```
    ])),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۳.۵: نمونهٔ حاشیه‌نویسی کتابخانه استاندارد
    ],
  )
  #v(1%)
])


#let figure-4-5 = align(center, [
  #v(2.5%)
  #rect(
    stroke: 0.5pt,
    width: 50%,
    align(left, text(dir: ltr, [
      #text(fill: black.lighten(35%), [
        *compile_commands.json*
      ])
      ```json

      [
          {
              "arguments": [
                  "/usr/bin/gcc",
                  "-c",
                  "main.c"
              ],
              "directory": "/root/",
              "file": "/root/main.c"
          },
      ]


      ```
    ])),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۴.۵: نمونهٔ ساختار فایل دستورهای کامپایل
    ],
  )
])

#let figure-5-5 = align(center, [
  #v(2.5%)
  #grid(
    columns: 2,
    gutter: 5pt,

    rect(
      stroke: 0.5pt,
      width: 100%,
      align(left, text(dir: ltr, [
        #text(fill: black.lighten(35%), [
          *main.c*
        ])
        ```c

        #include "foo.h"

        int main() {
                int a = SUM(1, 2);
                int b = multiply(2, 2);
                return 0;
        }


        ```
      ])),
    ),
    rect(
      stroke: 0.5pt,
      width: 100%,
      height: 182pt,
      align(left, text(dir: ltr, [
        #text(fill: black.lighten(35%), [
          *foo.h*
        ])
        ```c

        #define SUM(a, b) ((a) + (b))

        int multiply(int a, int b);


        ```
      ])),
    ),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۵.۵: نمونهٔ استفاده از ماکروها
    ],
  )
  #v(1%)
])

#let figure-6-5 = align(center, [
  #v(2.5%)
  #rect(
    stroke: 0.5pt,
    width: 60%,
    align(left, text(dir: ltr, [
      #text(fill: black.lighten(35%), [
        *main.c*
      ])
      ```c

      int multiply(int a, int b);

      int main() {
              int a = ((1) + (2));
              int b = multiply(2, 2);
              return 0;
      }


      ```
    ])),
  )
  #text(
    dir: rtl,
    size: 10pt,
    fill: black.lighten(35%),
    [
      #v(0.5%)
      شکل ۶.۵: نتیجه گسترش ماکروها در بخش پیش‌پردازش
    ],
  )
  #v(1%)
])

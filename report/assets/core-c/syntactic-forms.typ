
#let type-and-value-syntactic-forms = box(text(dir: ltr, [
  #line(length: 100%, stroke: 1.5pt)
  #grid(
    columns: (49%, 2%, 49%),
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Type's syntactic forms")
      \ \
      #math.lr(
        $
          "Type" & ::= "                                " &        "types:" \
                 & | "Unit"                               &     "unit type" \
                 & | "Int"                                &      "int type" \
                 & | "Bool"                               &     "bool type" \
                 & | "Type*"                              &  "pointer type" \
                 & | "Linear Type"                        &   "linear type" \
                 & | "Type" -> "Type"                     & "function type" \
        $,
      )
    ],
    line(angle: 90deg, length: 29%, stroke: 0.5pt),
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Value's syntactic forms")
      \ \
      #math.lr(
        $
          "value" & ::= "                          " &           "values:" \
                  & | "true"                         &     "constant true" \
                  & | "false"                        &    "constant false" \
                  & | "unit"                         &     "constant unit" \
                  & | "int"                          & "constant integers" \
        $,
      )
    ],
  )
  #line(length: 100%, stroke: 1.5pt)
]))

#let expression-and-operations-syntactic-forms = box(text(dir: ltr, [
  #line(length: 100%, stroke: 1.5pt)
  #grid(
    columns: (49%, 2%, 49%),
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Expression's syntactic forms")
      \ \
      #math.lr(
        $
          "expr" & ::= "                                 " &  "expressions:" \
                 & | "(expr)"                              & "parenthesized" \
                 & | "expr bin_op expr"                    &        "binary" \
                 & | "uni_op expr"                         &         "unary" \
                 & | "ident"                               &    "identifier" \
                 & | "value"                               &         "value" \
                 & | "ident(expr)"                         & "function call" \
        $,
      )
    ],
    line(angle: 90deg, length: 54%, stroke: 0.5pt),
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Binary operation's syntactic forms")
      \ \
      #math.lr(
        $
          "bin_op" & ::= "                       " & "binary operations:" \
                   & | +                           &           "addition" \
                   & | "&&"                        &                "and" \
                   & | "||"                        &                 "or" \
                   & | ==                          &              "equal" \
                   & | <                           &          "less than" \
                   & | >                           &       "greater than" \
        $,
      )
      \ \
      #text(size: 14pt, style: "italic", "Unary operation's syntactic forms")
      \ \
      #math.lr(
        $
          "un_op" & ::= "                         " & "unary operations:" \
                  & | -                             &          "negative" \
                  & | !                             &               "not" \
                  & | "&"                           &        "address of" \
                  & | *                             &       "dereference" \
        $,
      )
    ],
  )
  #line(length: 100%, stroke: 1.5pt)
]))

#let statement-syntactic-forms = box(text(dir: ltr, [
  #line(length: 59%, stroke: 1.5pt)
  #grid(
    columns: 1,
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Statement's syntactic forms")
      \ \
      #math.lr(
        $
          "stmt" & ::= "                                     " &          "statements:" \
                 & | "{ stmt }"                                &   "compound statement" \
                 & | "stmt stmt"                               &             "sequence" \
                 & | "if (expr) stmt else stmt"                &         "if statement" \
                 & | "while (expr) stmt"                       &      "while statement" \
                 & | "expr;"                                   & "expression statement" \
                 & | "Type ident;"                             &          "declaration" \
                 & | "ident = expr;"                           &           "assignment" \
                 & | "return expr;"                            &     "return statement" \
                 & | ";"                                       &  "semicolon statement" \
                 \
        $,
      )
    ],
  )
  #line(length: 59%, stroke: 1.5pt)
]))

#let program-syntactic-forms = box(text(dir: ltr, [
  #line(length: 78%, stroke: 1.5pt)
  #grid(
    columns: 1,
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Program's syntactic forms")
      \ \
      #math.lr(
        $
          "program" & ::=                                     &                  "program:" \
                    & | "Type ident(Type ident) stmt program" & "     function declaration" \
                    & | epsilon                               &             "empty-program" \
                    \
        $,
      )
    ],
  )
  #line(length: 78%, stroke: 1.5pt)
]))

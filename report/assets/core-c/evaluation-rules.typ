
#import "@preview/curryst:0.5.1": prooftree, rule

#let fn-and-env-definitions = box(text(dir: ltr, [
  #line(length: 100%, stroke: 1.5pt)
  #grid(
    columns: (49%, 2%, 49%),
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Env's definition")
      \ \
      #math.lr(
        $
          "Env" & ::= "                           " &      "enviroment:" \
                & | "Env", "ident:value"            &    "value binding" \
                & | epsilon                         & "empty enviroment" \
        $,
      )
    ],
    line(angle: 90deg, length: 16%, stroke: 0.5pt),
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Fn's definition")
      \ \
      #math.lr(
        $
          "Fn" & ::= "                                " &       "functions:" \
               & | "Fn", "ident:(ident, stmt)"          & "function binding" \
               & | epsilon                              &  "empty functions" \
        $,
      )
    ],
  )
  #line(length: 100%, stroke: 1.5pt)
]))

#let expression-evaluation-rules = box(text(dir: ltr, [
  #line(length: 72%, stroke: 1.5pt)
  #grid(
    columns: 1,
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Expression's evaluation rules")
      \ \
      #prooftree(
        rule(
          name: "[E-Parenthesized-Operand]",
          $"Fn"; "Env" tack.r ( e ) --> ( e' )$,
          $"Fn"; "Env" tack.r e --> e'$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Binary-Left-Operand]",
          $"Fn"; "Env" tack.r e_1 "bin_op" e_2 --> e'_1 "bin_op" e_2$,
          $"Fn"; "Env" tack.r e_1 --> e'_1$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Binary-Right-Operand]",
          $"Fn"; "Env" tack.r e_1 "bin_op" e_2 --> e_1 "bin_op" e'_2$,
          $"Fn"; "Env" tack.r e_2 --> e'_2$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Unary-Operand]",
          $"Fn"; "Env" tack.r "uni_op" e --> "uni_op" e'$,
          $"Fn"; "Env" tack.r e --> e'$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Function-Call-Argument]",
          $"Fn"; "Env" tack.r id (e) --> id (e')$,
          $"Fn"; "Env" tack.r e --> e'$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Identifier]",
          $"Fn"; "Env" tack.r "Env"(id)$,
          $id in "dom(Env)"$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Parenthesized]",
          $"Fn"; "Env" tack.r ( e ) --> e$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Binary]",
          $"Fn"; "Env" tack.r e_1 "bin_op" e_2 --> "binary_eval"("bin_op", e_1, e_2)$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Unary]",
          $"Fn"; "Env" tack.r "un_op" e --> "unary_eval"("un_op", e)$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Function-Call]",
          $"Fn"; id_2:e tack.r id (e) --> s'$,
          $"Fn"(id_1) = (id_2, s)$,
          $"Fn"; "Env", id_2:e tack.r s --> s'$,
        ),
      )
      \
    ],
  )
  #line(length: 72%, stroke: 1.5pt)
]))

#let statement-evaluation-rules = box(text(dir: ltr, [
  #line(length: 77%, stroke: 1.5pt)
  #grid(
    columns: 1,
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Statement's evaluation rules")
      \ \
      #prooftree(
        rule(
          name: "[E-Compound-Statement]",
          $"Fn"; "Env" tack.r { s } --> { s' }$,
          $"Fn"; "Env" tack.r s --> s'$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Sequence-Left-Statement]",
          $"Fn"; "Env" tack.r s_1 space s_2 --> s_1' space s_2$,
          $"Fn"; "Env" tack.r s_1 --> s_1'$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Sequence-Right-Statement]",
          $"Fn"; "Env" tack.r s_1 space s_2 --> s_1 space s_2'$,
          $"Fn"; "Env" tack.r s_2 --> s_2'$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-If-Statement-True]",
          $"Fn"; "Env" tack.r "if" "(true)" s_1 "else" s_2 --> s_1$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-If-Statement-False]",
          $"Fn"; "Env" tack.r "if" "(false)" s_1 "else" s_2 --> s_2$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-If-Statement]",
          $"Fn"; "Env" tack.r "if" (e) space s_1 "else" s_2 --> "if" (e') space s_1 "else" s_2$,
          $"Fn"; "Env" tack.r e --> e'$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-While-Statement]",
          $"Fn"; "Env" tack.r "while" (e) space s --> "if" (e) { space s "while" (e) space s } "else" ";"$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Expression-Statement]",
          $"Fn"; "Env" tack.r e; --> e';$,
          $"Fn"; "Env" tack.r e --> e'$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Assignment]",
          $"Fn"; "Env" tack.r id = e; --> id = e';, "Env"[id|->e']$,
          $"Fn"; "Env" tack.r e --> e'$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[E-Return-Statement]",
          $"Fn"; "Env" tack.r "return" e; --> "return" e';$,
          $"Fn"; "Env" tack.r e --> e'$,
        ),
      )
      \
    ],
  )
  #line(length: 77%, stroke: 1.5pt)
]))

#let program-evaluation-rules = box(text(dir: ltr, [
  #line(length: 100%, stroke: 1.5pt)
  #grid(
    columns: 1,
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Program's evaluation rules")
      \ \
      #prooftree(
        rule(
          name: "[E-Function-Declaration]",
          $"Fn"; "Env" tack.r T_1 space id_1 (T_2 space id_2) space s space p --> T_1 space id_1 (T_2 space id_2) space s space p', "Fn"[id_1 |-> (id_2, s)]$,
          $"Fn"; "Env" tack.r p --> p'$,
        ),
      )
      \
    ],
  )
  #line(length: 100%, stroke: 1.5pt)
]))

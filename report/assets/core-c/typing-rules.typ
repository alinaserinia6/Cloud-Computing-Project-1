
#import "@preview/curryst:0.5.1": prooftree, rule

#let gamma-and-delta-defenitions = box(text(dir: ltr, [
  #line(length: 100%, stroke: 1.5pt)
  #grid(
    columns: (49%, 2%, 49%),
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Type context's definition")
      \ \
      #math.lr(
        $
          Gamma & ::= "                             " &      "type context:" \
                & | Gamma, "ident:Type"               &       "type binding" \
                & | epsilon                           & "empty type context" \
        $,
      )
    ],
    line(angle: 90deg, length: 16%, stroke: 0.5pt),
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Linear context's definition")
      \ \
      #math.lr(
        $
          Delta & ::= "                          " &      "linear context:" \
                & | Delta, "ident"                 &                "owner" \
                & | epsilon                        & "empty linear context" \
        $,
      )
    ],
  )
  #line(length: 100%, stroke: 1.5pt)
]))

#let operations-typing-rules = box(text(dir: ltr, [
  #line(length: 100%, stroke: 1.5pt)
  #grid(
    columns: 1,
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Binary operation's typing rules")
      \ \
      #math.lr(
        $
          & "binary"(+, "Int", "Int") : "Int" space
          && "binary"("&&", "Bool", "Bool") : "Bool" space
          && "binary"("||", "Bool", "Bool") : "Bool" \
          & "binary"(==, "Bool", "Bool") : "Bool" space
          && "binary"(<, "Bool", "Bool") : "Bool" space
          && "binary"(>, "Bool", "Bool") : "Bool" \
        $,
      )
      #v(-1%)
      \
      #math.lr(
        $
          "binary"("bin_op", "Linear" T, T) : "binary"("bin_op", T, T) \
          "binary"("bin_op", T, "Linear" T) : "binary"("bin_op", T, T) \
        $,
      )
      \ \
      #line(length: 100%, stroke: 0.5pt)
      #v(1%)
      #text(dir: ltr, size: 14pt, style: "italic", "Unary operation's typing rules")
      \ \
      #math.lr(
        $
          & "unary"(-, "Int") : "Int"                            && "unary"(!, "Bool") : "Bool" \
          & "unary"("&", T) : T^*                                && "unary"(*, T^*) : T \
          & "unary"("uni_op", "Linear" T) : "unary"("uni_op", T)
        $,
      )
      \ \
    ],
  )
  #line(length: 100%, stroke: 1.5pt)
]))

#let expression-typing-rules = box(text(dir: ltr, [
  #line(length: 82%, stroke: 1.5pt)
  #grid(
    columns: 1,
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Expression's typing rules")
      \ \
      #prooftree(
        rule(
          name: "[T-Parenthesized]",
          $Gamma; Delta tack.r ( e ) : T$,
          $Gamma; Delta tack.r e : T$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Binary]",
          $Gamma; Delta tack.r e_1 "bin_op" e_2 : T_3$,
          $Gamma; Delta tack.r e_1 : T_1$,
          $Gamma; Delta tack.r e_2 : T_2$,
          $Gamma; Delta tack.r "binary"("bin_op", T_1, T_2) : T_3$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Unary]",
          $Gamma; Delta tack.r "uni_op" e : T'$,
          $Gamma; Delta tack.r e : T$,
          $Gamma; Delta tack.r "unary"("un_op", T) : T'$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Value]",
          $Gamma; Delta tack.r v : T$,
          $Gamma; Delta tack.r v : T$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Function-Call-Move]",
          $Gamma; Delta tack.r id_1 (id_2) : T', Delta backslash {id_2}$,
          $Gamma(id_1) = "Linear" T -> T'$,
          $Gamma(id_2) = "Linear" T$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Function-Call-Burrow]",
          $Gamma; Delta tack.r id_1 (id_2) : T'$,
          $Gamma(id_1) = T -> T'$,
          $Gamma(id_2) = "Linear" T$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Function-Call]",
          $Gamma; Delta tack.r id (e) : T'$,
          $Gamma(id) = "Linear" T -> T'$,
          $Gamma; Delta tack.r e : T$,
        ),
      )
      \
    ],
  )
  #line(length: 82%, stroke: 1.5pt)
]))

#let statement-typing-rules = box(text(dir: ltr, [
  #line(length: 88%, stroke: 1.5pt)
  #grid(
    columns: 1,
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Statement's typing rules")
      \ \
      #prooftree(
        rule(
          name: "[T-Compound-Statement]",
          $Gamma; Delta tack.r { s } : T$,
          $Gamma, Gamma'; Delta tack.r s : T$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Sequence]",
          $Gamma; Delta tack.r s_1 space s_2 : T_2$,
          $Gamma; Delta tack.r s_1 : T_1$,
          $Gamma; Delta tack.r s_2 : T_2$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-If-Statement]",
          $Gamma; Delta tack.r "if" (e) space s_1 "else" s_2 : T$,
          $Gamma; Delta tack.r s_1 : T$,
          $Gamma; Delta tack.r s_2 : T$,
          $Gamma; Delta tack.r e : "Bool"$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-While-Statement]",
          $Gamma; Delta tack.r "while" (e) space s : T$,
          $Gamma; Delta tack.r e : "Bool"$,
          $Gamma; Delta tack.r s : T$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Expression-Statement]",
          $Gamma; Delta tack.r e; : "Unit"$,
          $Gamma; Delta tack.r e : "Unit"$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Declaration]",
          $Gamma; Delta tack.r T space id; : "Unit", Gamma[id |-> T]$,
          $id in.not "dom"(Gamma)$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Assignment-Move]",
          $Gamma; Delta tack.r id_1 = id_2; : "Unit",
          (Delta backslash {id_2}) union {id_1}$,
          $Gamma(id_1) = "Linear" T$,
          $Gamma(id_2) = "Linear" T$,
          $id_1 in.not Delta$,
          $id_2 in Delta$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Assignment-Burrow]",
          $Gamma; Delta tack.r id_1 = id_2; : "Unit"$,
          $Gamma(id_1) = T$,
          $id_2 in Delta$,
          $Gamma(id_2) = "Linear" T$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Assignment-Linear]",
          $Gamma; Delta tack.r id = e; : "Unit", Delta union id$,
          $Gamma(id) = "Linear" T$,
          $id in.not Delta$,
          $Gamma; Delta tack.r e : "Linear" T$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Assignment]",
          $Gamma; Delta tack.r id = e; : "Unit"$,
          $Gamma(id) = T$,
          $Gamma; Delta tack.r e : T$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Return-Statement]",
          $Gamma; diameter tack.r "return" e; : "Unit"$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Semicolon-Statement]",
          $Gamma; Delta tack.r ";" : "Unit"$,
        ),
      )
      \
    ],
  )
  #line(length: 88%, stroke: 1.5pt)
]))

#let program-typing-rules = box(text(dir: ltr, [
  #line(length: 98%, stroke: 1.5pt)
  #grid(
    columns: 1,
    align: top + left,
    [
      #v(1%)
      #text(size: 14pt, style: "italic", "Program's typing rules")
      \ \
      #prooftree(
        rule(
          name: "[T-Function-Declaration-Linear-Argument]",
          $Gamma; diameter tack.r T_1 space id_1 ("Linear" T_2 space id_2) space s : T_3, Gamma[id |-> T_1 -> T_2]$,
          $id_1 in.not "dom"(Gamma)$,
          $Gamma, id_1:T_1, id_2:T_2; {id_2} tack.r s : T_3$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Function-Declaration]",
          $Gamma; diameter tack.r T_1 space id_1 (T_2 space id_2) space s : T_3, Gamma[id |-> T_1 -> T_2]$,
          $id_1 in.not "dom"(Gamma)$,
          $Gamma, id_1:T_1, id_2:T_2; diameter tack.r s : T_3$,
        ),
      )
      \
      #prooftree(
        rule(
          name: "[T-Empty-Program]",
          $Gamma; diameter tack.r epsilon : "Unit"$,
        ),
      )
      \
    ],
  )
  #line(length: 98%, stroke: 1.5pt)
]))

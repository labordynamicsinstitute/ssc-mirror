spex wlsrnk
label variable value1 "est"
label variable value2 "var"
label variable value3 "aut"
label variable value4 "sec"
case2alt, casevars(fem hn) rank(value) case(id) alt(hashi haslo) gen(rank)
quietly rologit rank estXfem estXhn est varXfem varXhn var ///
    autXfem autXhn aut hashi haslo, group(id) reverse nolog
estadd asprvalue, x(fem=1 hashi=0 haslo=0) base(sec) label(fem=1) brief save
estadd asprvalue, x(fem=0 hashi=0 haslo=0) base(sec) label(fem=0) brief
estadd asprvalue, x(fem=0 hashi=0 haslo=0) base(sec) label(diff)  brief diff
estadd asprvalue post, swap
esttab, not nostar unstack

spex wlsrnk
label variable value1 "est"
label variable value2 "var"
label variable value3 "aut"
label variable value4 "sec"
case2alt, casevars(fem hn) rank(value) case(id) alt(hashi haslo) gen(rank)
rologit rank estXfem estXhn est varXfem varXhn var ///
    autXfem autXhn aut hashi haslo, group(id) reverse nolog
estadd fitstat
estadd listcoef
estadd listcoef, percent replace
esttab, cell("b b_fact b_pct") scalars(aic0 aic_n bic0 bic_p)

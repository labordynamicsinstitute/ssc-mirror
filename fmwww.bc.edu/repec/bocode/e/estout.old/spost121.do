spex travel2
quietly asmprobit choice time invc, case(id) alternatives(mode) nolog
estadd asprvalue, label(at means)
estadd asprvalue, rest(asmean) label(at asmeans)
estadd asprvalue post, swap
esttab, unstack not nostar nomtitle nonumber

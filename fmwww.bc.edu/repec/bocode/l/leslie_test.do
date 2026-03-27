
********************
*leslie presentation
********************

help leslie
mata mata clear
run leslie.ado

use sweden_1993_bothsexes.dta, replace
des
list, sep(18) noobs

db leslie

*Two-sex projection assuming constant fertility and mortality 25 years forward
leslie, period(5) two stable summary

*Two-sex projection assuming the fertility standard and future life expectancy from the UN WPP (2024) median probabilistic variant
leslie, period(7) two base(1993) place(Sweden) surv(. .)

*Alternative fertility and mortality scenarios
leslie, period(7) two base(1993) fert(3) surv(85 82)

*Including constant migration rates residually calculated
leslie, p(7) two base(1993) fert(3) surv(85 82) mig1(Sweden_1988_bothsexes.dta) gr(nodraw)

*Multistate projections
use multi_race_brazil.dta, replace
des
l, noobs sepby(state)

*Multistate projections assuming constant transition rates over time + summary multistate measures 
leslie, p(6) multistate su

*Counterfactual scenario for multistate projections without mobility
leslie, p(6) multi nomobility

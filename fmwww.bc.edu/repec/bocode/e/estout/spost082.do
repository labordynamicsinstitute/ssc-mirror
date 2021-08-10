spex couart2
drop if art==0 // artificially truncated the data
eststo ztp: quietly ztp art fem mar kid5 phd ment, nolog
eststo ztnb: quietly ztnb art fem mar kid5 phd ment, nolog
estadd listcoef fem ment: *
estadd listcoef fem ment, percent nosd : *
esttab, cell("b_facts b_pcts") keep(fem ment) mtitles
eststo clear

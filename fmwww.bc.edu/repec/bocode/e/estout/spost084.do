spex couart2
drop if art==0 // artificially truncated the data
eststo ztp0: quietly ztp art fem mar kid5 phd ment, nolog
eststo ztnb0: quietly ztnb art fem mar kid5 phd ment, nolog
estadd prchange, outcome(0) : *0
eststo ztp1: quietly ztp art fem mar kid5 phd ment, nolog
eststo ztnb1: quietly ztnb art fem mar kid5 phd ment, nolog
estadd prchange, outcome(1) : *1
esttab, main(dc) nostar not scalars(outcome predval) mtitles
eststo clear

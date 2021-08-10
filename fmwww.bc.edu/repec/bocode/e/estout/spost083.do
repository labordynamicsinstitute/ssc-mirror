spex couart2
drop if art==0 // artificially truncated the data
eststo ztp: quietly ztp art fem mar kid5 phd ment, nolog
eststo ztnb: quietly ztnb art fem mar kid5 phd ment, nolog
estadd prchange: *
esttab, aux(dc) nopar wide mtitles
eststo clear

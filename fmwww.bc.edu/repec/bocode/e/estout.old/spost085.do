spex couart2
drop if art==0 // artificially truncated the data
eststo ztp: quietly ztp art fem mar kid5 phd ment, nolog
estadd prvalue
eststo ztnb: quietly ztnb art fem mar kid5 phd ment, nolog
estadd prvalue
estadd prvalue post, swap: *
esttab, b(4) nostar not mtitles eqlabels(none)
eststo clear

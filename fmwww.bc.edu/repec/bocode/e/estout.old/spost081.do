spex couart2
drop if art==0 // artificially truncated the data
eststo ztp: quietly ztp art fem mar kid5 phd ment, nolog
eststo ztnb: quietly ztnb art fem mar kid5 phd ment, nolog
estadd fitstat : *
esttab, wide scalars(r2_mf r2_mfadj aic0 aic_n) mtitles
eststo clear

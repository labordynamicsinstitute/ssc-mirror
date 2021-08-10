local list anovaplot anovaplot7 indexplot indexplot7 ofrtplot ofrtplot7 ///
ovfplot ovfplot7 qfrplot qfrplot7 racplot rdplot rdplot7 regplot regplot7 ///
rhetplot rvfplot2 rvfplot27 rvlrplot rvlrplot7 rvpplot2 rvpplot27
tempname HH
file open `HH' using modeldiag.rdf, write replace
foreach w of local list {
local f = substr("`w'",1,1)
file write `HH' "File-URL: http://fmwww.bc.edu/repec/bocode/`f'/`w'.ado" _n
file write `HH' "File-Format: text/plain" _n
file write `HH' "File-Function: program code" _n
file write `HH' "File-URL: http://fmwww.bc.edu/repec/bocode/`f'/`w'.hlp" _n
file write `HH' "File-Format: text/plain" _n
file write `HH' "File-Function: help file" _n
}
file close `HH'

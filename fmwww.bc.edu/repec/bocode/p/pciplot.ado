*! v 1.4.0 13feb2021
program define pciplot
version 15.1
/*
	Plot pointwise confidence intervals.
	Vars are y y_lci y_uci x or y y_se x.
	Default for the reference line is lstyle(refline).
	Lwidth() etc supplant the default if any is specified.
*/
syntax varlist(min=3 max=4 numeric) [if] [in] [, ADDplot(string asis) ///
 LWidth(string) LColor(string) LPattern(string) RAREAopts(string asis) ///
 ULim(string) LLim(string) EXPonential J *]

if "`j'" != "" {
	local cj connect(J J)
	local j
}
if "`llim'" != "" confirm number `llim'
if "`ulim'" != "" confirm number `ulim'
tokenize `varlist'
local i 1
while "``i''" != "" {
	confirm var ``i''
	local ++i
}
tempvar lci uci y
clonevar `y' = `1'
if `i' == 4 { // 3 arguments
	tempname z
	scalar `z' = invnormal((100 + c(level))/200)
	local x `3'
	qui gen `lci' = `y' - `z' * `2'
	qui gen `uci' = `y' + `z' * `2'
}
else { // 4 arguments
	local x `4'
	clonevar `lci' = `2'
	clonevar `uci' = `3'
}
if "`exponential'" != "" {
	qui replace `lci' = exp(`lci')
	qui replace `uci' = exp(`uci')
	qui replace `y' = exp(`y')
}
lab var `lci' "lower conf limit"
lab var `uci' "upper conf limit"
if "`llim'" != "" qui replace `lci' = max(`lci', `llim')
if "`ulim'" != "" qui replace `uci' = min(`uci', `ulim')

marksample touse
if ("`lwidth'`lcolor'`lpattern'" != "") local lstyle lwidth(`lwidth') lcolor(`lcolor') lpattern(`lpattern')
else local lstyle lstyle(refline)
/*
// Implement fill opacity 50% (fcolor(%50)) and invisible CI line border (lcolor(%0))
twoway (rarea `lci' `uci' `x' if `touse', sort pstyle(ci) fcolor(%50) lcolor(%0) ) ///
 (line `y' `x' if `touse', sort pstyle(p2) `lstyle') ///
 (`addplot') , `options'
*/
twoway ///
    rarea `lci' `uci' `x' if `touse', sort pstyle(ci) fcolor(%50) lcolor(%0) `cj' `rareaopts' 	///
 || line `y' `x' if `touse', sort pstyle(p2) `lstyle' `cj' `options'			///
 || `addplot'
end
exit

v 1.3.0: implement llim() and ulim(), truncation limits on lci and uci for plot
v 1.4.0: implement exponential transformation

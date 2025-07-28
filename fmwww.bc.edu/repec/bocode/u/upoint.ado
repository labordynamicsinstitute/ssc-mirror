*! upoint 1.0.0  Wu LiangHai 08jul2025
program upoint, eclass
	version 17.0
	syntax varlist(min=1 numeric ts fv) [if] [in], GENerate(string)
	marksample touse
	quietly count if `touse'
	if `r(N)' == 0 {
	        error 2000
	}
	qui cap generate `2'_`generate' = `2' * `generate'
	qui cap generate `3'_`generate' = `3' * `generate'
	local varnames "`varlist' `2'_`generate' `3'_`generate'"
	regress `varnames', vce(robust)
	matrix m = e(b)
	mat upoint =(m[1, "`2'"], m[1, "`3'"], m[1, "`2'_`generate'"], m[1,"`3'_`generate'"])
	mat list upoint
	clear
	svmat upoint, names(col)
	cap generate point = `2' * `3'_`generate' - `3' * `2'_`generate'
	list
	end


*! _xtpqcce_ebuild v1.0.0  20jun2026  Dr Merwan Roudane
*! Build named b/V for ereturn post from xtpqcce engine output.
*! Headline coefficients are the slope effects on x, one equation per
*! quantile (eq = qXX), so that test/lincom/coeflegend work.

capture program drop _xtpqcce_ebuild
program define _xtpqcce_ebuild, rclass
	version 15.1
	syntax , est(string) tau(numlist) k(integer) indepvars(string) ///
		lags(integer) mg(string) v(string) [ bcon(integer 0) bcmg(string) ]

	local ntau : word count `tau'
	local p = `ntau'*`k'

	tempname src
	if "`est'" == "csqr" & `bcon' matrix `src' = `bcmg'
	else                          matrix `src' = `mg'

	tempname B V
	matrix `B' = `src'[1, 1..`p']
	matrix `V' = `v'[1..`p', 1..`p']

	* equation:coef names
	local names ""
	local ti 0
	foreach q of local tau {
		local ++ti
		local qe = round(100*`q')
		forvalues j = 1/`k' {
			local xv : word `j' of `indepvars'
			local names "`names' q`qe':`xv'"
		}
	}
	matrix colnames `B' = `names'
	matrix colnames `V' = `names'
	matrix rownames `V' = `names'

	return matrix bpost = `B'
	return matrix vpost = `V'
end

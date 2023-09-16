*! version 1.0.0  15sep2023
program mareg_est, eclass
	version 9, missing
	syntax varlist(ts fv) [if] [in] [, * ]
	quietly regress $mareg_exp, `options'
	quietly summarize `=e(depvar)' if e(sample), meanonly
	mat b = e(b)
	mat b = e(b)/sqrt(e(r2))
	mat b[1,`:colsof(b)'] = b[1,`:colsof(b)'] + r(mean)*(1 - 1/sqrt(e(r2)))
	ereturn repost b = b
	end

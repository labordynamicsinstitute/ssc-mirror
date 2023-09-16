*! version 1.0.0  15sep2023
program magreg, eclass
	version 9, missing
	if !replay() {
		syntax varlist(ts fv) [if] [in] [aw fw iw pw] [, BSopts(string) * ]
		global magreg_exp `varlist' `if' `in' [`weight'`exp']
		quietly bootstrap, `bsopts': magreg_est $magreg_exp, `options' 
		}
	else {
		if strpos("`e(cmdline)'","mareg_est ")==0 error 301
		}
	display _n as txt "Maximum agreement regression" _c
	display _col(44) as txt "Number of obs           = " as res %9.0f e(N)
	display _col(44) as txt "R-squared               = " as res %9.4f e(r2)
	display _col(44) as txt "Concordance corr. coef. = " as res %9.4f sqrt(e(r2))
	ereturn display
	end

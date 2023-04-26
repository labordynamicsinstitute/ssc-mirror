*! version 1.0.1  17jan2019
program poswbic_gmm_logit
	version 16.0

	syntax varlist [if], 		///
		at(name) 		///
		yvar(string)		///
		xbvar(string)		///
		[derivatives(varlist) ]
	
	tempvar xb
	qui matrix score double `xb' = `at' `if' 

	tempvar exp_xb
	qui gen double `exp_xb' = exp(`xb' + `xbvar') `if'

	tempvar pr
	qui gen double `pr' = `exp_xb'/(1 + `exp_xb')

	qui replace `varlist' = `yvar' - `pr' `if'

	if (`"`derivatives'"' == "") {
		exit
		// NotReached
	}

	qui replace `derivatives' = -`pr'*(1-`pr') `if'
end

